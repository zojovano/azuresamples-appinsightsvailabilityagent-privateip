# App README

This directory contains the Azure Function App code for the Availability Agent.

## Structure

```
app/
├── src/
│   └── AvailabilityAgent/
│       ├── Models/
│       │   ├── ProbeConfiguration.cs    # Configuration models
│       │   └── ProbeResult.cs           # Result models
│       ├── AvailabilityFunction.cs      # Timer-triggered function
│       ├── AvailabilityProbe.cs         # Probe execution logic
│       ├── Configuration.cs             # Environment variable parsing
│       ├── Program.cs                   # Function host setup
│       ├── AvailabilityAgent.csproj     # Project file
│       ├── host.json                    # Function host configuration
│       └── local.settings.json          # Local development settings
├── Dockerfile                           # Container definition
└── .dockerignore
```

## Key Components

### AvailabilityFunction.cs
Timer-triggered Azure Function that:
- Runs on a configurable schedule
- Loads configuration from environment variables
- Executes probes for all configured endpoints
- Flushes telemetry to Application Insights

### AvailabilityProbe.cs
Core probe logic that:
- Makes HTTP requests to target endpoints
- Measures response time and status
- Handles timeouts and errors
- Tracks availability telemetry

### Configuration.cs
Configuration management that:
- Parses environment variables
- Supports multiple URL formats (JSON, comma-separated)
- Handles detailed probe configurations
- Validates settings

## Local Development

### Prerequisites
- .NET 8 SDK
- Azure Functions Core Tools
- Application Insights instance (or use local development key)

### Run Locally

1. Update `local.settings.json`:
```json
{
  "Values": {
    "APPLICATIONINSIGHTS_CONNECTION_STRING": "your-connection-string",
    "PROBE_URLS": "[\"https://www.microsoft.com\"]",
    "PROBE_FREQUENCY": "0 */1 * * * *"
  }
}
```

2. Start the function:
```bash
cd src/AvailabilityAgent
func start
```

3. Test manually:
```bash
# Trigger the timer function
curl http://localhost:7071/admin/functions/AvailabilityProbeFunction
```

## Building

### Build .NET Application
```bash
cd src/AvailabilityAgent
dotnet restore
dotnet build
dotnet publish -c Release -o ./publish
```

### Build Docker Container
```bash
cd app
docker build -t availabilityagent:latest .
```

### Test Container Locally
```bash
docker run -p 8080:80 \
  -e APPLICATIONINSIGHTS_CONNECTION_STRING="your-key" \
  -e PROBE_URLS='["https://www.microsoft.com"]' \
  -e PROBE_FREQUENCY="0 */5 * * * *" \
  availabilityagent:latest
```

## Configuration

### Environment Variables

**PROBE_URLS** (Required)
- Simple list: `["url1", "url2"]`
- Detailed: See CONFIGURATION.md

**PROBE_FREQUENCY** (Optional)
- Cron expression: `0 */5 * * * *`
- Default: Every 5 minutes

**PROBE_TIMEOUT_SECONDS** (Optional)
- Integer value in seconds
- Default: 30

**TEST_NAME_PREFIX** (Optional)
- String prefix for test names
- Default: "Private-Endpoint"

**TEST_LOCATION** (Optional)
- Location identifier string
- Default: "VNET-Integration"

**APPLICATIONINSIGHTS_CONNECTION_STRING** (Required)
- Application Insights connection string
- Auto-configured in Azure deployment

## Dependencies

Key NuGet packages:
- `Microsoft.Azure.Functions.Worker` - Functions runtime
- `Microsoft.ApplicationInsights.WorkerService` - App Insights SDK
- `Microsoft.Azure.Functions.Worker.ApplicationInsights` - Integration

See `AvailabilityAgent.csproj` for full list.

## Testing

### Unit Tests
```bash
cd src/AvailabilityAgent
dotnet test
```

### Integration Tests
Deploy to Azure and verify:
1. Function triggers on schedule
2. Telemetry appears in Application Insights
3. Availability tests show in dashboard

## Troubleshooting

### Function Not Executing
- Check timer trigger expression
- Verify Function App is running
- Check logs: `func azure functionapp logstream <function-app-name>`

### No Telemetry in App Insights
- Verify connection string is correct
- Check for errors in function logs
- Ensure telemetry flush is working
- Wait a few minutes for data to appear

### Probe Failures
- Check endpoint accessibility from VNET
- Verify timeout is sufficient
- Review error messages in logs
- Test connectivity manually

### Container Issues
- Ensure Dockerfile builds successfully
- Check container registry authentication
- Verify Function App can pull image
- Review container logs in Azure

## Performance Considerations

- **Parallel Execution**: All probes run concurrently
- **Timeout Settings**: Configure per endpoint needs
- **Telemetry Batching**: SDK batches telemetry automatically
- **Memory Usage**: Scales with number of endpoints

## Best Practices

1. **Error Handling**: All probes have comprehensive error handling
2. **Logging**: Structured logging with ILogger
3. **Telemetry**: Rich properties for filtering
4. **Configuration**: Externalized via environment variables
5. **Security**: No secrets in code
