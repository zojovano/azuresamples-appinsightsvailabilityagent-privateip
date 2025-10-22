# Azure Samples - App Insights Availability Agent for Private IP Endpoints

This is a containerized Azure Functions app that monitors the availability of private endpoints (URLs/IPs) using Azure Application Insights SDK. It emulates the functionality of the standard Application Insights availability agent, which only supports public endpoints, by leveraging VNET Integration to probe endpoints within private networks.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [Technology Stack](#technology-stack)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [Deployment](#deployment)
- [Local Development](#local-development)
- [Application Structure](#application-structure)
- [Infrastructure Details](#infrastructure-details)
- [Monitoring](#monitoring)
- [Cost Estimation](#cost-estimation)
- [Troubleshooting](#troubleshooting)
- [Best Practices](#best-practices)
- [Quick Reference](#quick-reference)
- [Contributing](#contributing)
- [License](#license)

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
- ✅ **Parallel probe execution** for all endpoints
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
│   │       │   ├── ProbeConfiguration.cs
│   │       │   └── ProbeResult.cs
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
│   ├── workflows/
│   │   └── deploy.yml           # CI/CD pipeline
│   └── ISSUE_TEMPLATE/
│       ├── bug_report.md
│       └── feature_request.md
│
├── build-and-run.ps1            # PowerShell script for local Docker
├── CONTRIBUTING.md              # Contribution guidelines
├── LICENSE
└── README.md
```

## Technology Stack

- **Language**: C# with .NET 8
- **Runtime**: Azure Functions v4 (isolated worker model)
- **Container**: Docker with multi-stage build
- **Infrastructure**: Terraform 1.6+ with azurerm provider
- **CI/CD**: GitHub Actions
- **Monitoring**: Azure Application Insights
- **SDK**: Microsoft.ApplicationInsights.WorkerService 2.22.0

## Quick Start

### Prerequisites

```bash
# Check Azure CLI
az --version

# Check Terraform
terraform --version

# Check .NET SDK
dotnet --version

# Check Docker
docker --version

# Check Azure Functions Core Tools
func --version

# Login to Azure
az login
```

Required tools:
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

Example `terraform.tfvars`:
```hcl
location     = "eastus"
environment  = "dev"
project_name = "availagent"

probe_urls = jsonencode([
  "https://api.internal.com/health",
  "https://web.internal.com"
])

probe_frequency       = "0 */5 * * * *"  # Every 5 minutes
probe_timeout_seconds = 30
test_name_prefix      = "Private-Endpoint"
test_location         = "VNET-Dev-EastUS"
```

### 3. Deploy Infrastructure

```bash
terraform init
terraform plan
terraform apply
```

### 4. Configure GitHub Secrets

Create Service Principal:
```bash
az ad sp create-for-rbac --name "github-actions-availagent" \
  --role Contributor \
  --scopes /subscriptions/<subscription-id> \
  --sdk-auth
```

Set GitHub secrets (Settings > Secrets and variables > Actions):
- `AZURE_CREDENTIALS` - Service Principal JSON output
- `ACR_LOGIN_SERVER` - From Terraform output
- `ACR_USERNAME` - From Terraform output
- `ACR_PASSWORD` - From Terraform output

### 5. Deploy via GitHub Actions

Push to the `main` branch to trigger the CI/CD pipeline:

```bash
git add .
git commit -m "Initial deployment"
git push origin main
```

## Configuration

### Environment Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `PROBE_URLS` | JSON array or comma-separated URLs | - | ✅ |
| `PROBE_FREQUENCY` | Cron expression for schedule | `0 */5 * * * *` | ❌ |
| `PROBE_TIMEOUT_SECONDS` | Request timeout in seconds | `30` | ❌ |
| `TEST_NAME_PREFIX` | Prefix for test names | `Private-Endpoint` | ❌ |
| `TEST_LOCATION` | Location identifier | `VNET-Integration` | ❌ |
| `APPLICATIONINSIGHTS_CONNECTION_STRING` | App Insights connection | Auto-configured | ✅ |

### Configuration Formats

#### 1. Simple Comma-Separated URLs
```bash
PROBE_URLS="https://api.internal.com,https://web.internal.com,http://10.0.1.50/health"
```

#### 2. JSON Array
```json
["https://api.internal.com", "https://web.internal.com", "http://10.0.1.50/health"]
```

#### 3. Detailed Configuration with Custom Settings
```json
[
  {
    "url": "https://api.internal.com/health",
    "testName": "Internal-API-Health",
    "timeoutSeconds": 30,
    "httpMethod": "GET",
    "headers": {
      "X-API-Key": "your-api-key",
      "Accept": "application/json"
    }
  },
  {
    "url": "http://10.0.1.50:8080/status",
    "testName": "Backend-Service-Status",
    "timeoutSeconds": 20,
    "httpMethod": "POST",
    "headers": {
      "Content-Type": "application/json",
      "Authorization": "Bearer token"
    }
  }
]
```

### Cron Schedule Examples

| Schedule | Cron Expression | Description |
|----------|----------------|-------------|
| Every 1 minute | `0 */1 * * * *` | Frequent monitoring |
| Every 5 minutes | `0 */5 * * * *` | Default setting |
| Every 15 minutes | `0 */15 * * * *` | Standard monitoring |
| Every 30 minutes | `0 */30 * * * *` | Light monitoring |
| Every hour | `0 0 */1 * * *` | Hourly checks |
| Daily at 9 AM | `0 0 9 * * *` | Daily health check |
| Weekdays at 9 AM | `0 0 9 * * 1-5` | Business hours only |

### Use Case Examples

#### Microservices Monitoring
```json
[
  {"url": "https://auth-service.internal.com/health", "testName": "Auth-Service"},
  {"url": "https://user-service.internal.com/health", "testName": "User-Service"},
  {"url": "https://order-service.internal.com/health", "testName": "Order-Service"},
  {"url": "https://payment-service.internal.com/health", "testName": "Payment-Service"}
]
```

#### Private Azure Services
```json
[
  {"url": "https://myapp.privatelink.azurewebsites.net", "testName": "Private-Web-App"},
  {"url": "https://myapi.privatelink.azurewebsites.net/health", "testName": "Private-API-App"},
  {"url": "https://mystorage.privatelink.blob.core.windows.net", "testName": "Private-Storage", "httpMethod": "HEAD"}
]
```

## Deployment

### Initial Setup (One-time)

1. **Configure Terraform variables**
   ```bash
   cd infra
   cp terraform.tfvars.example terraform.tfvars
   # Edit with your settings
   ```

2. **Deploy infrastructure manually**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

3. **Get ACR credentials**
   ```bash
   az acr credential show --name <acr-name> --resource-group <rg-name>
   ```

4. **Configure GitHub secrets**
   - AZURE_CREDENTIALS
   - ACR_LOGIN_SERVER
   - ACR_USERNAME
   - ACR_PASSWORD

5. **Build and push initial container**
   ```bash
   cd app
   az acr login --name <acr-name>
   docker build -t <acr-name>.azurecr.io/availabilityagent:latest .
   docker push <acr-name>.azurecr.io/availabilityagent:latest
   ```

6. **Update Function App**
   ```bash
   az functionapp config container set \
     --name <function-app-name> \
     --resource-group <rg-name> \
     --docker-custom-image-name <acr-name>.azurecr.io/availabilityagent:latest
   
   az functionapp restart --name <function-app-name> --resource-group <rg-name>
   ```

### Continuous Deployment (Automated)

After initial setup, all deployments are automated:
1. Make code or infrastructure changes
2. Commit and push to `main` branch
3. GitHub Actions automatically:
   - Builds .NET application
   - Creates and pushes Docker container
   - Deploys infrastructure changes
   - Updates Function App

### Verification

```bash
# Stream logs
az functionapp log tail --name <function-app-name> --resource-group <rg-name>

# Check Function status
az functionapp show --name <function-app-name> --resource-group <rg-name> --query "state"

# Query Application Insights
az monitor app-insights query \
  --app <app-insights-name> \
  --analytics-query "availabilityResults | where timestamp > ago(1h) | take 10"
```

## Local Development

### Run with Functions Runtime

1. Update `app/src/AvailabilityAgent/local.settings.json`:
   ```json
   {
     "IsEncrypted": false,
     "Values": {
       "AzureWebJobsStorage": "UseDevelopmentStorage=true",
       "FUNCTIONS_WORKER_RUNTIME": "dotnet-isolated",
       "APPLICATIONINSIGHTS_CONNECTION_STRING": "InstrumentationKey=00000000-0000-0000-0000-000000000000",
       "PROBE_URLS": "[\"https://www.microsoft.com\", \"https://www.azure.com\"]",
       "PROBE_FREQUENCY": "0 */1 * * * *",
       "PROBE_TIMEOUT_SECONDS": "30",
       "TEST_NAME_PREFIX": "Local-Test",
       "TEST_LOCATION": "Local-Development"
     }
   }
   ```

2. Run locally:
   ```bash
   cd app/src/AvailabilityAgent
   dotnet restore
   dotnet build
   func start
   ```

3. Test manually:
   ```bash
   curl http://localhost:7071/admin/functions/AvailabilityProbeFunction
   ```

### Build with .NET

```bash
cd app/src/AvailabilityAgent

# Restore packages
dotnet restore

# Build
dotnet build --configuration Release

# Publish
dotnet publish --configuration Release --output ./publish
```

### Run with Docker

#### Using PowerShell Script (Recommended)

```powershell
# Build and run (default)
.\build-and-run.ps1

# Just build
.\build-and-run.ps1 -Action Build

# Run with custom configuration
.\build-and-run.ps1 -Action Run `
  -ProbeUrls '["https://api.example.com"]' `
  -ProbeFrequency "0 */2 * * * *" `
  -ProbeTimeout 60

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

```bash
# Build
cd app
docker build -t availabilityagent:latest .

# Run
docker run -d --name availabilityagent \
  -p 8080:80 \
  -e APPLICATIONINSIGHTS_CONNECTION_STRING="your-key" \
  -e PROBE_URLS='["https://www.microsoft.com"]' \
  -e PROBE_FREQUENCY="0 */5 * * * *" \
  -e PROBE_TIMEOUT_SECONDS="30" \
  availabilityagent:latest

# View logs
docker logs -f availabilityagent

# Stop
docker stop availabilityagent

# Remove
docker rm availabilityagent
```

## Application Structure

### Key Components

#### AvailabilityFunction.cs
Timer-triggered Azure Function that:
- Runs on configurable cron schedule
- Loads configuration from environment variables
- Executes probes for all endpoints in parallel
- Flushes telemetry to Application Insights
- Caches configuration between executions

#### AvailabilityProbe.cs
Core probe logic that:
- Makes HTTP requests to target endpoints
- Measures response time and captures status codes
- Handles timeouts and network errors
- Tracks availability telemetry with Application Insights SDK
- Supports custom HTTP methods and headers

#### Configuration.cs
Configuration management that:
- Parses environment variables
- Supports multiple URL formats:
  - JSON array: `["url1", "url2"]`
  - Comma-separated: `url1,url2`
  - Detailed objects with headers and methods
- Validates settings and provides defaults
- Generates test names from URLs automatically

#### Models
- **ProbeConfiguration**: Per-endpoint configuration (URL, timeout, headers, method)
- **ProbeResult**: Probe execution results (success, duration, status, errors)
- **AppConfiguration**: Global application settings

### Dependencies

Key NuGet packages:
- `Microsoft.Azure.Functions.Worker` 1.22.0 - Functions runtime
- `Microsoft.Azure.Functions.Worker.Sdk` 1.17.2 - SDK and tools
- `Microsoft.ApplicationInsights.WorkerService` 2.22.0 - App Insights SDK
- `Microsoft.Azure.Functions.Worker.ApplicationInsights` 1.2.0 - Integration
- `Microsoft.Azure.Functions.Worker.Extensions.Timer` 4.3.0 - Timer trigger support

## Infrastructure Details

### Azure Resources Created

The Terraform configuration creates:

1. **Resource Group** - Container for all resources
2. **Virtual Network** - Private network (default: 10.0.0.0/16)
3. **Subnet** - Delegated for Function App integration (default: 10.0.1.0/24)
4. **Application Insights** - Monitoring and availability tracking
5. **Log Analytics Workspace** - Backend for Application Insights
6. **Container Registry** - Stores Docker images (with admin access enabled)
7. **Storage Account** - Required for Azure Functions
8. **App Service Plan** - Linux Premium (P1v2) plan
9. **Function App** - Containerized function with VNET Integration

### Terraform Variables

#### Required
- `probe_urls` - JSON array of URLs to monitor

#### Optional (with defaults)
- `location` - Azure region (default: "eastus")
- `environment` - Environment name (default: "dev")
- `project_name` - Project identifier (default: "availagent")
- `probe_frequency` - Cron schedule (default: "0 */5 * * * *")
- `probe_timeout_seconds` - Timeout in seconds (default: 30)
- `test_name_prefix` - Test name prefix (default: "Private-Endpoint")
- `test_location` - Location identifier (default: "VNET-Integration")
- `vnet_address_space` - VNET CIDR (default: ["10.0.0.0/16"])
- `function_subnet_address_prefix` - Subnet CIDR (default: ["10.0.1.0/24"])

### Terraform Outputs

After deployment, outputs include:
- Resource Group name
- Function App name and default hostname
- Application Insights connection string and instrumentation key
- Container Registry login server, username, and password
- VNET and subnet IDs
- Log Analytics Workspace ID

### Network Configuration

Default network settings:
- **VNET**: 10.0.0.0/16
- **Function Subnet**: 10.0.1.0/24 (delegated to Microsoft.Web/serverFarms)

Adjust these in `terraform.tfvars` if they conflict with existing networks:
```hcl
vnet_address_space             = ["192.168.0.0/16"]
function_subnet_address_prefix = ["192.168.1.0/24"]
```

### Remote State Management

For team collaboration, configure remote state:

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

## Monitoring

### Application Insights Dashboard

After deployment, availability tests appear in Azure Portal:

1. Navigate to Application Insights resource
2. Go to **Availability** section
3. View custom availability tests with:
   - Success rates
   - Response times
   - Geographic distribution (based on TEST_LOCATION)
   - Historical trends

### Setting Up Alerts

Create availability alerts:
```bash
az monitor metrics alert create \
  --name "availability-alert" \
  --resource-group <rg-name> \
  --scopes /subscriptions/<sub-id>/resourceGroups/<rg-name>/providers/microsoft.insights/components/<app-insights-name> \
  --condition "avg availabilityResults/availabilityPercentage < 95" \
  --window-size 5m \
  --evaluation-frequency 1m
```

### KQL Queries for Monitoring

#### View all availability tests
```kql
availabilityResults
| where timestamp > ago(1h)
| summarize 
    SuccessCount = countif(success == true),
    FailureCount = countif(success == false),
    AvgDuration = avg(duration)
    by name, location
| order by name
```

#### Failed probes
```kql
availabilityResults
| where timestamp > ago(24h) and success == false
| project timestamp, name, location, message, duration
| order by timestamp desc
```

#### Success rate by endpoint
```kql
availabilityResults
| where timestamp > ago(24h)
| summarize 
    Total = count(),
    Success = countif(success == true),
    SuccessRate = round(100.0 * countif(success == true) / count(), 2)
    by name
| order by SuccessRate asc
```

#### Response time trends
```kql
availabilityResults
| where timestamp > ago(24h) and success == true
| summarize AvgDuration = avg(duration) by bin(timestamp, 5m), name
| render timechart
```

## Cost Estimation

### Monthly Costs (East US Region)

| Resource | SKU | Approximate Cost |
|----------|-----|------------------|
| Function App | P1v2 Premium | ~$73/month |
| Application Insights | Pay-as-you-go | ~$2-10/month |
| Storage Account | Standard LRS | ~$1-5/month |
| Virtual Network | - | Free |
| Container Registry | Basic | ~$5/month |
| **Total** | | **~$81-93/month** |

### Cost Optimization

**Development/Test Environments:**
- Use B1 or S1 App Service Plan (~$13-55/month)
- Reduce probe frequency (every 15-30 minutes)
- Shorter log retention (30 days)
- Disable Always On

**Production Optimizations:**
- Use reserved instances for App Service Plan
- Configure sampling in Application Insights
- Use lifecycle policies for ACR images
- Monitor and optimize telemetry volume

**Alternative: Consumption Plan**
- Pay-per-execution pricing
- Trade-off: Cold start delays (not recommended for frequent probes)

## Troubleshooting

### Function Not Executing

**Symptoms**: Timer trigger not firing, no logs in Application Insights

**Solutions**:
- Verify timer trigger expression: `az functionapp config appsettings list --name <name> --resource-group <rg> | grep PROBE_FREQUENCY`
- Check Function App status: `az functionapp show --name <name> --resource-group <rg> --query "state"`
- Review Function App logs: `az functionapp log tail --name <name> --resource-group <rg>`
- Verify Always On is enabled for App Service Plan
- Check for deployment failures in Azure Portal

### No Telemetry in Application Insights

**Symptoms**: No data in Availability section, missing traces

**Solutions**:
- Verify connection string: Check `APPLICATIONINSIGHTS_CONNECTION_STRING` in App Settings
- Wait 2-5 minutes for data to propagate
- Check telemetry flush in logs
- Verify Application Insights ingestion: `az monitor app-insights component show --app <name> --resource-group <rg>`
- Check sampling configuration in `host.json`
- Review for SDK version compatibility issues

### Probe Failures

**Symptoms**: Tests show as failed, timeout errors, connection refused

**Solutions**:
- **VNET Connectivity**: Verify VNET Integration is active
  ```bash
  az functionapp vnet-integration list --name <name> --resource-group <rg>
  ```
- **DNS Resolution**: Test from Kudu console
  - Navigate to `https://<function-app-name>.scm.azurewebsites.net/DebugConsole`
  - Run: `curl -v <your-internal-endpoint>`
- **Timeout**: Increase `PROBE_TIMEOUT_SECONDS` for slow endpoints
- **Firewall Rules**: Check NSG rules on target subnet
- **Private Endpoint**: Verify private endpoint configuration and DNS
- **Test from VM**: Deploy test VM in same VNET to verify connectivity

### Container Issues

**Symptoms**: Container failed to start, image pull errors

**Solutions**:
- **Build locally**: Test Docker build on local machine
  ```bash
  cd app
  docker build -t availabilityagent:latest .
  docker run -p 8080:80 availabilityagent:latest
  ```
- **ACR Authentication**: Verify credentials in Function App
  ```bash
  az acr credential show --name <acr-name> --resource-group <rg-name>
  ```
- **Image exists**: Confirm image in ACR
  ```bash
  az acr repository show-tags --name <acr-name> --repository availabilityagent
  ```
- **Pull logs**: Check container deployment logs in Azure Portal > Deployment Center
- **Registry access**: Ensure Function App can access ACR (check firewall rules)

### Terraform Deployment Issues

**Error: Container image not found**
```
Solution: Deploy infrastructure first, then build/push container
1. terraform apply (infrastructure only)
2. Build and push container to ACR
3. Update Function App with container image
```

**Error: Subnet delegation conflict**
```
Solution: Ensure subnet is exclusively for Function Apps
- Remove existing delegations or use different subnet
- Check: az network vnet subnet show --name <subnet> --vnet-name <vnet> --resource-group <rg>
```

**Error: Name already exists (ACR, Storage, Function App)**
```
Solution: Resource names must be globally unique
- Modify project_name or environment in terraform.tfvars
- Example: project_name = "availagent-mycompany"
```

### Network Connectivity Issues

**VNET Address Space Conflicts**
- Default: 10.0.0.0/16
- Adjust if overlapping with existing networks
- Update both `vnet_address_space` and `function_subnet_address_prefix`

**Private Endpoint Not Accessible**
- Verify DNS resolution: Use nslookup from Function App
- Check routing: Ensure Function subnet can route to private endpoint subnet
- Test with Network Watcher: Connection troubleshoot tool
- Verify private DNS zone configuration

### Performance Issues

**Symptoms**: Slow probe execution, timeouts, high memory usage

**Solutions**:
- **Parallel Execution**: Probes run concurrently - expected behavior
- **Timeout Tuning**: Set per-endpoint timeouts appropriately
- **Memory**: Scale up if monitoring many endpoints (>50)
- **Plan SKU**: Upgrade from P1v2 to P2v2 or P3v2 if needed
- **Network Latency**: Check VNET to target latency
- **Telemetry Volume**: Review Application Insights sampling

### Common Configuration Mistakes

1. **Invalid JSON**: Ensure `PROBE_URLS` is valid JSON
   ```bash
   # Test JSON validity
   echo $PROBE_URLS | jq .
   ```

2. **Wrong Cron Syntax**: Verify cron expression (6 fields for Azure Functions)
   - Correct: `0 */5 * * * *` (seconds, minutes, hours, day, month, day-of-week)
   - Incorrect: `*/5 * * * *` (missing seconds field)

3. **Connection String vs Key**: Must use full connection string, not instrumentation key
   - Correct: `InstrumentationKey=xxx;IngestionEndpoint=https://...`
   - Incorrect: `xxx-xxx-xxx-xxx` (key only)

4. **Timeout Format**: Must be integer when using detailed configuration
   ```json
   {"url": "...", "timeoutSeconds": 30}  // Correct
   {"url": "...", "timeoutSeconds": "30"}  // Incorrect (string)
   ```

### Debugging Tips

**Enable Debug Logging**

Update `app/src/AvailabilityAgent/host.json`:
```json
{
  "version": "2.0",
  "logging": {
    "logLevel": {
      "default": "Information",
      "AvailabilityAgent": "Debug",
      "Microsoft.Azure.Functions.Worker": "Debug"
    }
  }
}
```

**Test Locally First**
```bash
# Run with func start
cd app/src/AvailabilityAgent
func start

# Test trigger manually
curl http://localhost:7071/admin/functions/AvailabilityProbeFunction
```

**Monitor in Real-Time**
```bash
# Stream Function logs
az functionapp log tail --name <function-app-name> --resource-group <rg-name>

# Query recent traces
az monitor app-insights query \
  --app <app-insights-name> \
  --analytics-query "traces | where timestamp > ago(10m) | order by timestamp desc"

# Check availability results
az monitor app-insights query \
  --app <app-insights-name> \
  --analytics-query "availabilityResults | where timestamp > ago(1h) | take 20"
```

**Kudu Console Access**
- URL: `https://<function-app-name>.scm.azurewebsites.net/DebugConsole`
- Test connectivity: `curl -v <internal-endpoint>`
- Check DNS: `nslookup <internal-hostname>`
- View environment: `printenv | grep PROBE`

## Best Practices

### Security

1. **Secrets Management**
   - Store all secrets in Azure Key Vault
   - Use Managed Identity for authentication
   - Never commit secrets to source control
   - Rotate ACR credentials regularly

2. **Network Security**
   - Use Network Security Groups (NSGs) to restrict traffic
   - Enable private endpoints for Storage and ACR
   - Configure firewall rules for Application Insights
   - Implement least-privilege access

3. **Authentication**
   - Use System-assigned Managed Identity
   - Grant minimum required RBAC roles
   - Disable ACR admin account in production
   - Use Azure AD authentication for ACR

4. **Monitoring**
   - Enable diagnostic logs for all resources
   - Configure security alerts
   - Monitor for unauthorized access attempts
   - Regular security audits

### Reliability

1. **Error Handling**
   - Comprehensive try-catch blocks in all probes
   - Graceful degradation on partial failures
   - Telemetry for all error conditions
   - Timeout handling for slow endpoints

2. **Retry Logic**
   - Implement exponential backoff for transient failures
   - Configure appropriate retry policies
   - Distinguish between retriable and non-retriable errors

3. **Health Monitoring**
   - Monitor the monitoring solution itself
   - Set up alerts for Function App failures
   - Track telemetry ingestion lag
   - Configure availability alerts

4. **High Availability**
   - Use Premium plan with Always On
   - Consider multi-region deployment
   - Configure backup and disaster recovery
   - Document failover procedures

### Operations

1. **Logging**
   - Use structured logging with ILogger
   - Include correlation IDs for tracing
   - Log appropriate detail levels
   - Avoid logging sensitive data

2. **Telemetry**
   - Rich custom properties for filtering
   - Consistent naming conventions
   - Track custom metrics
   - Monitor telemetry costs

3. **Alerting**
   - Set up alerts for availability thresholds
   - Configure action groups for notifications
   - Document alert response procedures
   - Regular alert effectiveness reviews

4. **Documentation**
   - Keep configuration documented
   - Maintain runbooks for common issues
   - Document architecture decisions
   - Track changes in CHANGELOG

### Development

1. **Infrastructure as Code**
   - All infrastructure in Terraform
   - Version control for all code
   - Use remote state storage
   - Implement state locking

2. **CI/CD**
   - Automated builds and tests
   - Deployment approvals for production
   - Rollback procedures
   - Blue-green deployments

3. **Version Control**
   - Tag all releases
   - Semantic versioning for containers
   - Branch protection rules
   - Code review requirements

4. **Testing**
   - Test locally before deployment
   - Integration tests for probes
   - Load testing for performance
   - Regular penetration testing

## Quick Reference

### Common Commands

```bash
# Local Development
cd app/src/AvailabilityAgent
dotnet restore
dotnet build
func start

# Docker
docker build -t availabilityagent:latest .
docker run -p 8080:80 availabilityagent:latest
docker logs -f availabilityagent

# Terraform
cd infra
terraform init
terraform plan
terraform apply
terraform destroy
terraform output

# Azure CLI - Function App
az functionapp list --output table
az functionapp show --name <name> --resource-group <rg>
az functionapp log tail --name <name> --resource-group <rg>
az functionapp restart --name <name> --resource-group <rg>

# Azure CLI - ACR
az acr login --name <acr-name>
az acr credential show --name <acr-name> --resource-group <rg>
az acr repository list --name <acr-name>
az acr repository show-tags --name <acr-name> --repository availabilityagent

# Azure CLI - Monitoring
az monitor app-insights query --app <name> --analytics-query "availabilityResults | take 10"
az functionapp config appsettings list --name <name> --resource-group <rg>

# GitHub CLI
gh secret set AZURE_CREDENTIALS < credentials.json
gh secret list
gh workflow run deploy.yml
gh run list
```

### Useful KQL Queries

```kql
// Recent availability results
availabilityResults
| where timestamp > ago(1h)
| project timestamp, name, location, success, duration, message

// Failed tests
availabilityResults
| where timestamp > ago(24h) and success == false
| order by timestamp desc

// Success rate trend
availabilityResults
| where timestamp > ago(7d)
| summarize SuccessRate = 100.0 * countif(success == true) / count() by bin(timestamp, 1h)
| render timechart

// Function execution traces
traces
| where timestamp > ago(1h)
| where message contains "Probing"
| project timestamp, message, severityLevel
```

### Quick Troubleshooting Checklist

- [ ] Function App is running
- [ ] Timer trigger expression is valid
- [ ] VNET Integration is configured
- [ ] Application Insights connection string is set
- [ ] Container image exists in ACR
- [ ] ACR credentials are correct
- [ ] Target endpoints are accessible from VNET
- [ ] DNS resolves correctly
- [ ] No NSG blocks
- [ ] Telemetry appears in App Insights (wait 2-5 min)

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

Key areas for contribution:
- Additional protocol support (TCP, UDP)
- Enhanced monitoring dashboards
- Terraform modules
- Unit and integration tests
- Documentation improvements
- Bug fixes and optimizations

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support and Resources

### Support Channels
- **Issues**: Open an issue in this repository
- **Discussions**: Use GitHub Discussions for questions
- **Documentation**: Review troubleshooting section above

### External Resources
- [Azure Functions Documentation](https://docs.microsoft.com/azure/azure-functions/)
- [Application Insights Documentation](https://docs.microsoft.com/azure/azure-monitor/app/app-insights-overview)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [GitHub Actions Documentation](https://docs.github.com/actions)
- [Azure Verified Modules](https://aka.ms/avm)

## Acknowledgments

- Built with [Azure Verified Modules](https://aka.ms/avm)
- Uses Application Insights SDK for custom availability tracking
- Implements Azure Functions isolated worker model
- Inspired by standard Application Insights availability tests

---

**Version**: 1.0.0  
**Last Updated**: October 22, 2025  
**Status**: Production Ready ✅
