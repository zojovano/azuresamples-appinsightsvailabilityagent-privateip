using System.Text.Json;
using AvailabilityAgent.Models;

namespace AvailabilityAgent;

public static class Configuration
{
    public static AppConfiguration LoadConfiguration()
    {
        var config = new AppConfiguration
        {
            ProbeFrequency = Environment.GetEnvironmentVariable("PROBE_FREQUENCY") ?? "0 */5 * * * *",
            TestNamePrefix = Environment.GetEnvironmentVariable("TEST_NAME_PREFIX") ?? "Private-Endpoint",
            TestLocation = Environment.GetEnvironmentVariable("TEST_LOCATION") ?? "VNET-Integration"
        };

        // Parse timeout
        if (int.TryParse(Environment.GetEnvironmentVariable("PROBE_TIMEOUT_SECONDS"), out var timeout))
        {
            config.DefaultTimeoutSeconds = timeout;
        }

        // Parse probe URLs
        var probeUrlsEnv = Environment.GetEnvironmentVariable("PROBE_URLS");
        if (!string.IsNullOrEmpty(probeUrlsEnv))
        {
            config.ProbeUrls = ParseProbeUrls(probeUrlsEnv, config);
        }

        return config;
    }

    private static List<ProbeConfiguration> ParseProbeUrls(string probeUrlsEnv, AppConfiguration appConfig)
    {
        var probeConfigs = new List<ProbeConfiguration>();

        try
        {
            // Try to parse as JSON array first
            if (probeUrlsEnv.TrimStart().StartsWith("["))
            {
                var jsonOptions = new JsonSerializerOptions
                {
                    PropertyNameCaseInsensitive = true
                };
                
                var urls = JsonSerializer.Deserialize<List<string>>(probeUrlsEnv, jsonOptions);
                if (urls != null)
                {
                    foreach (var url in urls)
                    {
                        probeConfigs.Add(new ProbeConfiguration
                        {
                            Url = url,
                            TestName = $"{appConfig.TestNamePrefix}-{GetTestNameFromUrl(url)}",
                            TimeoutSeconds = appConfig.DefaultTimeoutSeconds
                        });
                    }
                }
            }
            // Try to parse as JSON object array with detailed configuration
            else if (probeUrlsEnv.TrimStart().StartsWith("{"))
            {
                var jsonOptions = new JsonSerializerOptions
                {
                    PropertyNameCaseInsensitive = true
                };
                
                var configs = JsonSerializer.Deserialize<List<ProbeConfiguration>>(probeUrlsEnv, jsonOptions);
                if (configs != null)
                {
                    foreach (var config in configs)
                    {
                        if (string.IsNullOrEmpty(config.TestName))
                        {
                            config.TestName = $"{appConfig.TestNamePrefix}-{GetTestNameFromUrl(config.Url)}";
                        }
                        if (config.TimeoutSeconds <= 0)
                        {
                            config.TimeoutSeconds = appConfig.DefaultTimeoutSeconds;
                        }
                        probeConfigs.Add(config);
                    }
                }
            }
            else
            {
                // Parse as comma-separated URLs
                var urls = probeUrlsEnv.Split(new[] { ',', ';' }, StringSplitOptions.RemoveEmptyEntries);
                foreach (var url in urls)
                {
                    var trimmedUrl = url.Trim();
                    if (!string.IsNullOrEmpty(trimmedUrl))
                    {
                        probeConfigs.Add(new ProbeConfiguration
                        {
                            Url = trimmedUrl,
                            TestName = $"{appConfig.TestNamePrefix}-{GetTestNameFromUrl(trimmedUrl)}",
                            TimeoutSeconds = appConfig.DefaultTimeoutSeconds
                        });
                    }
                }
            }
        }
        catch (JsonException ex)
        {
            throw new InvalidOperationException($"Failed to parse PROBE_URLS environment variable: {ex.Message}", ex);
        }

        if (probeConfigs.Count == 0)
        {
            throw new InvalidOperationException("No probe URLs configured. Please set the PROBE_URLS environment variable.");
        }

        return probeConfigs;
    }

    private static string GetTestNameFromUrl(string url)
    {
        try
        {
            var uri = new Uri(url);
            var host = uri.Host.Replace(".", "-");
            var path = uri.AbsolutePath.Trim('/').Replace("/", "-");
            return string.IsNullOrEmpty(path) ? host : $"{host}-{path}";
        }
        catch
        {
            return url.Replace(":", "-").Replace("/", "-").Replace(".", "-");
        }
    }
}
