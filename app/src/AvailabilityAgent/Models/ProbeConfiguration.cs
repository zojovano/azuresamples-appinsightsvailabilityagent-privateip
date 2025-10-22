namespace AvailabilityAgent.Models;

public class ProbeConfiguration
{
    public string Url { get; set; } = string.Empty;
    public string TestName { get; set; } = string.Empty;
    public int TimeoutSeconds { get; set; } = 30;
    public string HttpMethod { get; set; } = "GET";
    public Dictionary<string, string>? Headers { get; set; }
}

public class AppConfiguration
{
    public List<ProbeConfiguration> ProbeUrls { get; set; } = new();
    public string ProbeFrequency { get; set; } = "0 */5 * * * *";
    public int DefaultTimeoutSeconds { get; set; } = 30;
    public string TestNamePrefix { get; set; } = "Private-Endpoint";
    public string TestLocation { get; set; } = "VNET-Integration";
}
