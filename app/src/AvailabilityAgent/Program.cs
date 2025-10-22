using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.ApplicationInsights.Extensibility;
using Microsoft.ApplicationInsights.WorkerService;

var host = new HostBuilder()
    .ConfigureFunctionsWorkerDefaults()
    .ConfigureServices(services =>
    {
        services.AddApplicationInsightsTelemetryWorkerService();
        services.ConfigureFunctionsApplicationInsights();

        // Configure Application Insights
        services.AddSingleton<ITelemetryInitializer, CustomTelemetryInitializer>();

        // Register HttpClient for making HTTP requests
        services.AddHttpClient();
        services.AddScoped<HttpClient>(serviceProvider =>
        {
            var httpClientFactory = serviceProvider.GetRequiredService<IHttpClientFactory>();
            var client = httpClientFactory.CreateClient();
            client.DefaultRequestHeaders.Add("User-Agent", "Azure-AvailabilityAgent/1.0");
            return client;
        });
    })
    .Build();

host.Run();

// Custom telemetry initializer to add common properties
public class CustomTelemetryInitializer : ITelemetryInitializer
{
    public void Initialize(Microsoft.ApplicationInsights.Channel.ITelemetry telemetry)
    {
        telemetry.Context.Cloud.RoleName = "AvailabilityAgent";
        telemetry.Context.Component.Version = "1.0.0";
    }
}
