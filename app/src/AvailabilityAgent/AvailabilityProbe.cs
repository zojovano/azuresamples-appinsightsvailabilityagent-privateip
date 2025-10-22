using System.Diagnostics;
using AvailabilityAgent.Models;
using Microsoft.ApplicationInsights;
using Microsoft.ApplicationInsights.DataContracts;
using Microsoft.ApplicationInsights.Extensibility;
using Microsoft.Extensions.Logging;

namespace AvailabilityAgent;

public class AvailabilityProbe
{
    private readonly TelemetryClient _telemetryClient;
    private readonly HttpClient _httpClient;
    private readonly ILogger _logger;
    private readonly string _testLocation;

    public AvailabilityProbe(TelemetryClient telemetryClient, HttpClient httpClient, ILogger logger, string testLocation)
    {
        _telemetryClient = telemetryClient;
        _httpClient = httpClient;
        _logger = logger;
        _testLocation = testLocation;
    }

    public async Task<ProbeResult> ExecuteProbeAsync(ProbeConfiguration config)
    {
        var result = new ProbeResult
        {
            Url = config.Url,
            Timestamp = DateTime.UtcNow
        };

        var stopwatch = Stopwatch.StartNew();
        var availabilityTelemetry = new AvailabilityTelemetry
        {
            Name = config.TestName,
            RunLocation = _testLocation,
            Success = false,
            Timestamp = result.Timestamp
        };

        try
        {
            _logger.LogInformation("Probing endpoint: {Url}", config.Url);

            // Configure request
            using var request = new HttpRequestMessage(
                new HttpMethod(config.HttpMethod),
                config.Url
            );

            // Add custom headers if configured
            if (config.Headers != null)
            {
                foreach (var header in config.Headers)
                {
                    request.Headers.TryAddWithoutValidation(header.Key, header.Value);
                }
            }

            // Set timeout for this specific request
            using var cts = new CancellationTokenSource(TimeSpan.FromSeconds(config.TimeoutSeconds));

            // Execute the probe
            using var response = await _httpClient.SendAsync(request, cts.Token);

            stopwatch.Stop();
            result.Duration = stopwatch.Elapsed;
            result.StatusCode = (int)response.StatusCode;
            result.Success = response.IsSuccessStatusCode;

            availabilityTelemetry.Success = result.Success;
            availabilityTelemetry.Duration = result.Duration;
            availabilityTelemetry.Properties.Add("StatusCode", result.StatusCode.ToString());
            availabilityTelemetry.Properties.Add("Url", config.Url);
            availabilityTelemetry.Properties.Add("HttpMethod", config.HttpMethod);

            if (!result.Success)
            {
                result.ErrorMessage = $"HTTP {result.StatusCode}: {response.ReasonPhrase}";
                availabilityTelemetry.Message = result.ErrorMessage;
                _logger.LogWarning("Probe failed for {Url}: {ErrorMessage}", config.Url, result.ErrorMessage);
            }
            else
            {
                _logger.LogInformation("Probe succeeded for {Url}: {StatusCode} in {Duration}ms", 
                    config.Url, result.StatusCode, result.Duration.TotalMilliseconds);
            }
        }
        catch (TaskCanceledException ex)
        {
            stopwatch.Stop();
            result.Duration = stopwatch.Elapsed;
            result.Success = false;
            result.ErrorMessage = $"Request timeout after {config.TimeoutSeconds} seconds";

            availabilityTelemetry.Success = false;
            availabilityTelemetry.Duration = result.Duration;
            availabilityTelemetry.Message = result.ErrorMessage;
            availabilityTelemetry.Properties.Add("Url", config.Url);
            availabilityTelemetry.Properties.Add("ErrorType", "Timeout");

            _logger.LogError(ex, "Probe timeout for {Url}", config.Url);
        }
        catch (HttpRequestException ex)
        {
            stopwatch.Stop();
            result.Duration = stopwatch.Elapsed;
            result.Success = false;
            result.ErrorMessage = $"HTTP request error: {ex.Message}";

            availabilityTelemetry.Success = false;
            availabilityTelemetry.Duration = result.Duration;
            availabilityTelemetry.Message = result.ErrorMessage;
            availabilityTelemetry.Properties.Add("Url", config.Url);
            availabilityTelemetry.Properties.Add("ErrorType", "HttpRequestException");

            _logger.LogError(ex, "Probe failed for {Url}", config.Url);
        }
        catch (Exception ex)
        {
            stopwatch.Stop();
            result.Duration = stopwatch.Elapsed;
            result.Success = false;
            result.ErrorMessage = $"Unexpected error: {ex.Message}";

            availabilityTelemetry.Success = false;
            availabilityTelemetry.Duration = result.Duration;
            availabilityTelemetry.Message = result.ErrorMessage;
            availabilityTelemetry.Properties.Add("Url", config.Url);
            availabilityTelemetry.Properties.Add("ErrorType", ex.GetType().Name);

            _logger.LogError(ex, "Unexpected error probing {Url}", config.Url);
        }

        // Track availability telemetry
        _telemetryClient.TrackAvailability(availabilityTelemetry);

        return result;
    }

    public async Task<List<ProbeResult>> ExecuteAllProbesAsync(List<ProbeConfiguration> probeConfigurations)
    {
        var tasks = probeConfigurations.Select(ExecuteProbeAsync);
        var results = await Task.WhenAll(tasks);
        return results.ToList();
    }
}
