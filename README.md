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

1. Update `local.settings.json` with your configuration
2. Run locally:
   ```bash
   cd app/src/AvailabilityAgent
   func start
   ```

## Cost Estimation

Approximate monthly costs (East US region):
- Function App (P1v2): ~$73
- Application Insights: ~$2-10 (depending on telemetry volume)
- Storage Account: ~$1-5
- Virtual Network: Free
- Container Registry (Basic): ~$5

**Total**: ~$81-93/month

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

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
