using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;
using Microsoft.ApplicationInsights;
using Microsoft.ApplicationInsights.Extensibility;

namespace AvailabilityAgent;

public class AvailabilityFunction
{
    private readonly ILogger _logger;
    private readonly TelemetryClient _telemetryClient;
    private readonly HttpClient _httpClient;
    private static readonly object _configLock = new object();
    private static Models.AppConfiguration? _cachedConfig;

    public AvailabilityFunction(ILoggerFactory loggerFactory, TelemetryClient telemetryClient, HttpClient httpClient)
    {
        _logger = loggerFactory.CreateLogger<AvailabilityFunction>();
        _telemetryClient = telemetryClient;
        _httpClient = httpClient;
    }

    [Function("AvailabilityProbeFunction")]
    public async Task Run([TimerTrigger("%PROBE_FREQUENCY%")] TimerInfo myTimer)
    {
        _logger.LogInformation("Availability Probe Function executed at: {Time}", DateTime.UtcNow);

        try
        {
            // Load configuration
            var config = GetConfiguration();

            if (config.ProbeUrls == null || config.ProbeUrls.Count == 0)
            {
                _logger.LogWarning("No probe URLs configured. Skipping execution.");
                return;
            }

            _logger.LogInformation("Executing {Count} availability probes", config.ProbeUrls.Count);

            // Create probe executor
            var probe = new AvailabilityProbe(_telemetryClient, _httpClient, _logger, config.TestLocation);

            // Execute all probes
            var results = await probe.ExecuteAllProbesAsync(config.ProbeUrls);

            // Log summary
            var successCount = results.Count(r => r.Success);
            var failureCount = results.Count(r => !r.Success);

            _logger.LogInformation(
                "Probe execution completed. Success: {SuccessCount}, Failed: {FailureCount}, Total Duration: {Duration}ms",
                successCount,
                failureCount,
                results.Sum(r => r.Duration.TotalMilliseconds)
            );

            // Flush telemetry to ensure it's sent to Application Insights
            _telemetryClient.Flush();
            await Task.Delay(1000); // Give it time to flush
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error executing availability probes");
            throw;
        }

        if (myTimer.ScheduleStatus is not null)
        {
            _logger.LogInformation("Next timer schedule at: {NextSchedule}", myTimer.ScheduleStatus.Next);
        }
    }

    private Models.AppConfiguration GetConfiguration()
    {
        // Cache configuration to avoid parsing on every execution
        if (_cachedConfig == null)
        {
            lock (_configLock)
            {
                if (_cachedConfig == null)
                {
                    _cachedConfig = Configuration.LoadConfiguration();
                }
            }
        }
        return _cachedConfig;
    }
}
