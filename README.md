# Azure Samples - App Insights Availability Agent for Private IP Endpoints

This is a containerized Azure Functions app that monitors the availability of private endpoints (URLs/IPs) using Azure Application Insights SDK. It emulates the functionality of the standard Application Insights availability agent, which only supports public endpoints, by leveraging VNET Integration to probe endpoints within private networks.

## Overview

The solution enables monitoring of:
- Private internal APIs and web applications
- Services behind private endpoints
- Resources accessible only within Azure VNETs
- On-premises services connected via VPN/ExpressRoute

## Features

- ✅ **Timer-triggered availability probes** for private endpoints
- ✅ **VNET Integration** for accessing private networks
- ✅ **Application Insights integration** with custom availability telemetry
- ✅ **Configurable probe settings** via environment variables
- ✅ **Support for multiple endpoints** with individual configurations
- ✅ **Custom HTTP methods and headers**
- ✅ **Containerized deployment** using Docker
- ✅ **Infrastructure as Code** using Terraform
- ✅ **CI/CD pipeline** with GitHub Actions
- ✅ **.NET 8** with isolated worker model

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        Azure                                 │
│                                                              │
│  ┌────────────────────────────────────────────────┐        │
│  │  Function App (Container)                      │        │
│  │  ┌──────────────────────────────────────────┐  │        │
│  │  │  Timer Trigger (Configurable Schedule)   │  │        │
│  │  │         ↓                                │  │        │
│  │  │  Availability Probe Logic                │  │        │
│  │  │         ↓                                │  │        │
│  │  │  Application Insights SDK                │  │        │
│  │  └──────────────────────────────────────────┘  │        │
│  │                 ↓ VNET Integration             │        │
│  └─────────────────┼────────────────────────────────        │
│                    ↓                                        │
│  ┌─────────────────┼────────────────────────────┐          │
│  │        Virtual Network (VNET)                 │          │
│  │                 ↓                             │          │
│  │   [Private Endpoints / Internal Services]    │          │
│  └───────────────────────────────────────────────┘          │
│                                                              │
│  ┌───────────────────────────────────────────────┐         │
│  │     Application Insights                      │         │
│  │     (Availability Dashboard & Alerts)         │         │
│  └───────────────────────────────────────────────┘         │
└─────────────────────────────────────────────────────────────┘
```

## Project Structure

```
.
├── app/                          # Application code
│   ├── src/
│   │   └── AvailabilityAgent/   # Function App
│   │       ├── Models/           # Data models
│   │       ├── AvailabilityFunction.cs
│   │       ├── AvailabilityProbe.cs
│   │       ├── Configuration.cs
│   │       ├── Program.cs
│   │       ├── AvailabilityAgent.csproj
│   │       ├── host.json
│   │       └── local.settings.json
│   ├── Dockerfile               # Container definition
│   └── .dockerignore
│
├── infra/                       # Infrastructure as Code
│   ├── main.tf                  # Main Terraform configuration
│   ├── variables.tf             # Variable definitions
│   ├── outputs.tf               # Output definitions
│   ├── providers.tf             # Provider configuration
│   └── terraform.tfvars.example # Example variables
│
├── .github/
│   └── workflows/
│       └── deploy.yml           # CI/CD pipeline
│
├── DEPLOYMENT.md                # Deployment guide
├── CONFIGURATION.md             # Configuration examples
├── LICENSE
└── README.md
```

## Technology Stack

- **Language**: C# with .NET 8
- **Runtime**: Azure Functions (isolated worker model)
- **Container**: Docker
- **Infrastructure**: Terraform with Azure Verified Modules
- **CI/CD**: GitHub Actions
- **Monitoring**: Azure Application Insights

## Quick Start

### Prerequisites

- Azure subscription
- Azure CLI
- Terraform >= 1.6
- .NET 8 SDK
- Docker (for local testing)
- GitHub account

### 1. Clone the Repository

```bash
git clone https://github.com/zojovano/azuresamples-appinsightsvailabilityagent-privateip.git
cd azuresamples-appinsightsvailabilityagent-privateip
```

### 2. Configure Terraform

```bash
cd infra
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your configuration
```

### 3. Deploy Infrastructure

```bash
terraform init
terraform plan
terraform apply
```

### 4. Configure GitHub Secrets

Set up the following secrets in your GitHub repository:

- `AZURE_CREDENTIALS` - Service Principal JSON
- `ACR_LOGIN_SERVER` - Container Registry URL
- `ACR_USERNAME` - ACR admin username
- `ACR_PASSWORD` - ACR admin password

### 5. Deploy via GitHub Actions

Push to the `main` branch to trigger the CI/CD pipeline:

```bash
git add .
git commit -m "Initial deployment"
git push origin main
```

## Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `PROBE_URLS` | JSON array of URLs to probe | Required |
| `PROBE_FREQUENCY` | Cron expression for schedule | `0 */5 * * * *` |
| `PROBE_TIMEOUT_SECONDS` | Request timeout | `30` |
| `TEST_NAME_PREFIX` | Prefix for test names | `Private-Endpoint` |
| `TEST_LOCATION` | Location identifier | `VNET-Integration` |

### Example Configuration

**Simple URL list:**
```json
["https://api.internal.com", "http://10.0.1.50/health"]
```

**Advanced configuration:**
```json
[
  {
    "url": "https://api.internal.com/health",
    "testName": "Internal-API",
    "timeoutSeconds": 30,
    "httpMethod": "GET",
    "headers": {
      "X-API-Key": "your-key"
    }
  }
]
```

See [CONFIGURATION.md](CONFIGURATION.md) for more examples.

## Deployment

See [DEPLOYMENT.md](DEPLOYMENT.md) for detailed deployment instructions including:
- Initial setup and configuration
- GitHub Actions setup
- Manual deployment steps
- Monitoring and verification
- Troubleshooting

## Monitoring

After deployment, availability tests will appear in Azure Application Insights:

1. Navigate to Application Insights in Azure Portal
2. Go to **Availability** section
3. View your custom availability tests with success rates and response times
4. Set up alerts based on availability thresholds

## Local Development

### Prerequisites
- .NET 8 SDK
- Azure Functions Core Tools
- Docker (optional, for container testing)
- Application Insights instance (or use local development key)

### Run Locally with Functions Runtime

1. Update `app/src/AvailabilityAgent/local.settings.json`:
   ```json
   {
     "IsEncrypted": false,
     "Values": {
       "AzureWebJobsStorage": "UseDevelopmentStorage=true",
       "FUNCTIONS_WORKER_RUNTIME": "dotnet-isolated",
       "APPLICATIONINSIGHTS_CONNECTION_STRING": "InstrumentationKey=00000000-0000-0000-0000-000000000000",
       "PROBE_URLS": "[\"https://www.microsoft.com\", \"https://www.azure.com\"]",
       "PROBE_FREQUENCY": "0 */5 * * * *",
       "PROBE_TIMEOUT_SECONDS": "30",
       "TEST_NAME_PREFIX": "Private-Endpoint",
       "TEST_LOCATION": "Local-Development"
     }
   }
   ```

2. Start the function:
   ```bash
   cd app/src/AvailabilityAgent
   func start
   ```

3. Test manually:
   ```bash
   # Trigger the timer function
   curl http://localhost:7071/admin/functions/AvailabilityProbeFunction
   ```

### Build .NET Application

```bash
cd app/src/AvailabilityAgent
dotnet restore
dotnet build --configuration Release
dotnet publish --configuration Release --output ./publish
```

### Build and Run with Docker

#### Using PowerShell Script (Recommended)

```powershell
# Build and run (default action)
.\build-and-run.ps1

# Just build
.\build-and-run.ps1 -Action Build

# Run with custom configuration
.\build-and-run.ps1 -Action Run -ProbeUrls '["https://api.example.com"]' -ProbeFrequency "0 */2 * * * *"

# View logs
.\build-and-run.ps1 -Action Logs

# Check status
.\build-and-run.ps1 -Action Status

# Stop container
.\build-and-run.ps1 -Action Stop

# Clean up
.\build-and-run.ps1 -Action Clean

# Get help
Get-Help .\build-and-run.ps1 -Detailed
```

#### Manual Docker Commands

Build the container:
```bash
cd app
docker build -t availabilityagent:latest .
```

Run the container:
```bash
docker run -d --name availabilityagent \
  -p 8080:80 \
  -e APPLICATIONINSIGHTS_CONNECTION_STRING="your-connection-string" \
  -e PROBE_URLS='["https://www.microsoft.com"]' \
  -e PROBE_FREQUENCY="0 */5 * * * *" \
  -e PROBE_TIMEOUT_SECONDS="30" \
  -e TEST_NAME_PREFIX="Private-Endpoint" \
  -e TEST_LOCATION="Local-Docker" \
  availabilityagent:latest
```

View container logs:
```bash
docker logs -f availabilityagent
```

## Application Structure

### Key Components

**`app/src/AvailabilityAgent/AvailabilityFunction.cs`**
- Timer-triggered Azure Function
- Runs on a configurable schedule
- Loads configuration from environment variables
- Executes probes for all configured endpoints
- Flushes telemetry to Application Insights

**`app/src/AvailabilityAgent/AvailabilityProbe.cs`**
- Core probe logic
- Makes HTTP requests to target endpoints
- Measures response time and status
- Handles timeouts and errors
- Tracks availability telemetry with Application Insights SDK

**`app/src/AvailabilityAgent/Configuration.cs`**
- Configuration management
- Parses environment variables
- Supports multiple URL formats (JSON array, comma-separated, detailed objects)
- Validates settings

**`app/src/AvailabilityAgent/Models/`**
- `ProbeConfiguration.cs` - Configuration models
- `ProbeResult.cs` - Result models

### Dependencies

Key NuGet packages:
- `Microsoft.Azure.Functions.Worker` 1.22.0 - Functions runtime
- `Microsoft.Azure.Functions.Worker.Sdk` 1.17.2 - SDK
- `Microsoft.ApplicationInsights.WorkerService` 2.22.0 - App Insights SDK
- `Microsoft.Azure.Functions.Worker.ApplicationInsights` 1.2.0 - Integration
- `Microsoft.Azure.Functions.Worker.Extensions.Timer` 4.3.0 - Timer trigger

## Infrastructure Details

### Resources Created

The Terraform configuration (`infra/`) creates:

1. **Resource Group** - Container for all resources
2. **Virtual Network** - Private network for Function App (10.0.0.0/16)
3. **Subnet** - Delegated subnet for Function App VNET Integration (10.0.1.0/24)
4. **Application Insights** - Monitoring and availability tracking
5. **Log Analytics Workspace** - Backend for Application Insights
6. **Container Registry** - Stores Docker images
7. **Storage Account** - Required for Azure Functions
8. **App Service Plan** - Linux Premium plan (P1v2) for Function App
9. **Function App** - Containerized function with VNET Integration

### Terraform Variables

#### Required
- `probe_urls` - JSON array of URLs to monitor

#### Optional (with defaults)
- `location` - Azure region (default: "eastus")
- `environment` - Environment name (default: "dev")
- `project_name` - Project identifier (default: "availagent")
- `probe_frequency` - Cron schedule (default: "0 */5 * * * *")
- `probe_timeout_seconds` - Timeout (default: 30)
- `test_name_prefix` - Test name prefix (default: "Private-Endpoint")
- `test_location` - Location identifier (default: "VNET-Integration")
- `vnet_address_space` - VNET CIDR (default: ["10.0.0.0/16"])
- `function_subnet_address_prefix` - Subnet CIDR (default: ["10.0.1.0/24"])

### Terraform Outputs

After deployment, Terraform outputs:
- Resource Group name
- Function App name and URL
- Application Insights connection string and key
- Container Registry login server, username, password
- VNET and subnet IDs

### Network Configuration

The default configuration creates:
- VNET: 10.0.0.0/16
- Function Subnet: 10.0.1.0/24

Adjust in `terraform.tfvars` if these conflict with your existing networks.

### State Management

For team collaboration, consider using remote state:

```hcl
# Add to infra/providers.tf
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "sttfstate"
    container_name       = "tfstate"
    key                  = "availagent.tfstate"
  }
}
```

## Cost Estimation

Approximate monthly costs (East US region):
- Function App (P1v2): ~$73
- Application Insights: ~$2-10 (depending on telemetry volume)
- Storage Account: ~$1-5
- Virtual Network: Free
- Container Registry (Basic): ~$5

**Total**: ~$81-93/month

### Cost Optimization Tips

To reduce costs in non-production environments:
- Use B1 or S1 App Service Plan SKU
- Reduce probe frequency (longer intervals)
- Use shorter retention periods for logs
- Consider consumption plan if cold start is acceptable

## Troubleshooting

### Function Not Executing
- Check timer trigger expression in configuration
- Verify Function App is running in Azure Portal
- Check Application Insights logs for errors
- Use Azure CLI: `az functionapp logs tail --name <function-app-name> --resource-group <rg-name>`

### No Telemetry in App Insights
- Verify connection string is correct in Function App settings
- Check for errors in function logs
- Ensure telemetry flush is working
- Wait 2-5 minutes for data to appear in Azure Portal
- Verify Application Insights is in same region or has proper routing

### Probe Failures
- Check endpoint accessibility from VNET
- Verify VNET Integration is properly configured
- Test connectivity manually from a VM in the same VNET
- Review timeout settings - increase if needed
- Check for firewall rules or NSG blocking traffic
- Review error messages in Application Insights logs

### Container Issues
- Ensure Dockerfile builds successfully locally
- Check container registry authentication in Function App
- Verify Function App can pull image (check deployment logs)
- Review container logs in Azure Portal under "Log stream"
- Validate image exists in ACR: `az acr repository show-tags --name <acr-name> --repository availabilityagent`

### Terraform Deployment Issues

**Error: Container image not found**
- Deploy infrastructure first without worrying about container
- Build and push container to ACR after infrastructure is created
- Update Function App with container image URL

**Error: Subnet delegation conflict**
- Ensure subnet is only used for Function Apps
- Check for existing delegations: `az network vnet subnet show --name <subnet-name> --vnet-name <vnet-name> --resource-group <rg-name>`
- Remove conflicting delegations or use a different subnet

**Error: Name already exists**
- Resource names must be globally unique (ACR, Storage, Function App)
- Modify `project_name` or `environment` variables in `terraform.tfvars`

### Network Connectivity Issues

**VNET Address Space Conflicts**
- Default VNET uses 10.0.0.0/16
- Adjust `vnet_address_space` and `function_subnet_address_prefix` if conflicts occur
- Ensure no overlap with on-premises networks or other VNETs

**Private Endpoint Not Accessible**
- Verify DNS resolution from Function App
- Check private endpoint configuration
- Ensure proper routing between subnets
- Test with Azure Network Watcher

### Performance Issues
- **Parallel Execution**: All probes run concurrently by default
- **Timeout Settings**: Configure per endpoint needs
- **Telemetry Batching**: SDK batches telemetry automatically
- **Memory Usage**: Scales with number of endpoints
- Consider scaling up Function App SKU if needed

### Common Configuration Mistakes

1. **JSON Format**: Ensure `PROBE_URLS` is valid JSON array
2. **Cron Expression**: Verify `PROBE_FREQUENCY` syntax
3. **Timeout Values**: Must be integers (not strings) for programmatic access
4. **Connection String**: Must include full App Insights connection string, not just instrumentation key

### Debugging Tips

**Enable Detailed Logging**
Add to `host.json`:
```json
{
  "logging": {
    "logLevel": {
      "default": "Information",
      "AvailabilityAgent": "Debug"
    }
  }
}
```

**Test Locally First**
- Run with `func start` before deploying
- Use mock Application Insights key for local testing
- Verify probes execute and return expected results

**Monitor in Real-Time**
```bash
# Stream logs
az functionapp log tail --name <function-app-name> --resource-group <rg-name>

# Query Application Insights
az monitor app-insights query --app <app-insights-name> --analytics-query "availabilityResults | take 10"
```

## Best Practices

### Security
1. **No Secrets in Code**: All sensitive data via environment variables
2. **Managed Identity**: Use for Azure resource authentication when possible
3. **Private Endpoints**: Consider for App Insights and Storage Account
4. **Network Security**: Use NSGs to restrict traffic

### Reliability
1. **Error Handling**: Comprehensive error handling in all probes
2. **Timeout Configuration**: Set appropriate timeouts per endpoint
3. **Retry Logic**: Consider implementing retry for transient failures
4. **Health Checks**: Monitor the monitoring solution itself

### Operations
1. **Structured Logging**: Use ILogger with structured properties
2. **Rich Telemetry**: Include custom properties for filtering
3. **Alerting**: Set up alerts on availability thresholds
4. **Documentation**: Keep configuration documented

### Development
1. **Infrastructure as Code**: Always use Terraform for deployments
2. **CI/CD Pipeline**: Automate builds and deployments
3. **Version Control**: Tag releases and container images
4. **Testing**: Test locally before deploying to Azure

## Contributing

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For issues and questions:
- Check [DEPLOYMENT.md](DEPLOYMENT.md) for troubleshooting
- Review Application Insights logs
- Open an issue in this repository

## Acknowledgments

- Built with [Azure Verified Modules](https://aka.ms/avm)
- Uses Application Insights SDK for custom availability tracking
- Implements Azure Functions isolated worker model
