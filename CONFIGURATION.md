# Configuration Examples

This document provides various configuration examples for different use cases.

## Basic Configuration

### Simple URL List (Comma-Separated)

```bash
PROBE_URLS="https://api.internal.com,https://web.internal.com,http://10.0.1.50/health"
PROBE_FREQUENCY="0 */5 * * * *"
PROBE_TIMEOUT_SECONDS="30"
TEST_NAME_PREFIX="Private-Endpoint"
TEST_LOCATION="VNET-EastUS"
```

### JSON Array of URLs

```bash
PROBE_URLS='["https://api.internal.com", "https://web.internal.com", "http://10.0.1.50/health"]'
PROBE_FREQUENCY="0 */5 * * * *"
PROBE_TIMEOUT_SECONDS="30"
TEST_NAME_PREFIX="Private-Endpoint"
TEST_LOCATION="VNET-EastUS"
```

## Advanced Configuration

### Detailed Probe Configuration with Custom Settings

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
    "url": "https://web-app.internal.com",
    "testName": "Internal-Web-App",
    "timeoutSeconds": 45,
    "httpMethod": "GET"
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
  },
  {
    "url": "https://database-proxy.internal.com:5432/health",
    "testName": "Database-Proxy",
    "timeoutSeconds": 15,
    "httpMethod": "GET"
  }
]
```

## Schedule Examples

### Cron Expression Reference

| Schedule | Cron Expression | Description |
|----------|----------------|-------------|
| Every 1 minute | `0 */1 * * * *` | Frequent monitoring |
| Every 5 minutes | `0 */5 * * * *` | Default setting |
| Every 15 minutes | `0 */15 * * * *` | Standard monitoring |
| Every 30 minutes | `0 */30 * * * *` | Light monitoring |
| Every hour | `0 0 */1 * * *` | Hourly checks |
| Every 6 hours | `0 0 */6 * * *` | Periodic checks |
| Every day at 9 AM | `0 0 9 * * *` | Daily health check |
| Business hours only | `0 */5 * * * 1-5` | Mon-Fri every 5 min |

## Terraform Variable Examples

### terraform.tfvars - Development Environment

```hcl
location     = "eastus"
environment  = "dev"
project_name = "availagent"

probe_urls = jsonencode([
  "https://dev-api.internal.com/health",
  "https://dev-web.internal.com",
  "http://10.0.1.50/status"
])

probe_frequency       = "0 */5 * * * *"
probe_timeout_seconds = 30
test_name_prefix      = "Dev-Private-Endpoint"
test_location         = "VNET-Dev-EastUS"

vnet_address_space             = ["10.0.0.0/16"]
function_subnet_address_prefix = ["10.0.1.0/24"]

tags = {
  Project     = "AvailabilityAgent"
  Environment = "Development"
  ManagedBy   = "Terraform"
  CostCenter  = "IT-Operations"
  Owner       = "devops-team@company.com"
}
```

### terraform.tfvars - Production Environment

```hcl
location     = "eastus"
environment  = "prod"
project_name = "availagent"

probe_urls = jsonencode([
  "https://api.company.com/health",
  "https://web-app.company.com",
  "http://10.1.1.100/status",
  "https://db-proxy.internal.com:5432/health"
])

probe_frequency       = "0 */2 * * * *"  # Every 2 minutes for critical systems
probe_timeout_seconds = 45
test_name_prefix      = "Prod-Critical"
test_location         = "VNET-Prod-EastUS"

vnet_address_space             = ["10.1.0.0/16"]
function_subnet_address_prefix = ["10.1.1.0/24"]

tags = {
  Project     = "AvailabilityAgent"
  Environment = "Production"
  ManagedBy   = "Terraform"
  CostCenter  = "IT-Operations"
  Owner       = "devops-team@company.com"
  Criticality = "High"
  Compliance  = "SOC2"
}
```

## Multi-Region Configuration

### Region 1 - East US

```hcl
location     = "eastus"
environment  = "prod"
project_name = "availagent-east"

probe_urls = jsonencode([
  "https://api-east.internal.com/health",
  "https://web-east.internal.com"
])

test_location = "VNET-Prod-EastUS"
```

### Region 2 - West US

```hcl
location     = "westus"
environment  = "prod"
project_name = "availagent-west"

probe_urls = jsonencode([
  "https://api-west.internal.com/health",
  "https://web-west.internal.com"
])

test_location = "VNET-Prod-WestUS"
```

## Use Case Examples

### Microservices Health Monitoring

```json
[
  {
    "url": "https://auth-service.internal.com/health",
    "testName": "Auth-Service",
    "timeoutSeconds": 30,
    "httpMethod": "GET"
  },
  {
    "url": "https://user-service.internal.com/health",
    "testName": "User-Service",
    "timeoutSeconds": 30,
    "httpMethod": "GET"
  },
  {
    "url": "https://order-service.internal.com/health",
    "testName": "Order-Service",
    "timeoutSeconds": 30,
    "httpMethod": "GET"
  },
  {
    "url": "https://payment-service.internal.com/health",
    "testName": "Payment-Service",
    "timeoutSeconds": 45,
    "httpMethod": "GET"
  },
  {
    "url": "https://notification-service.internal.com/health",
    "testName": "Notification-Service",
    "timeoutSeconds": 20,
    "httpMethod": "GET"
  }
]
```

### Database and Infrastructure Monitoring

```json
[
  {
    "url": "https://sql-proxy.internal.com:1433/health",
    "testName": "SQL-Proxy",
    "timeoutSeconds": 15,
    "httpMethod": "GET"
  },
  {
    "url": "https://redis-proxy.internal.com:6379/ping",
    "testName": "Redis-Cache",
    "timeoutSeconds": 10,
    "httpMethod": "GET"
  },
  {
    "url": "https://mongodb-proxy.internal.com:27017/health",
    "testName": "MongoDB",
    "timeoutSeconds": 20,
    "httpMethod": "GET"
  },
  {
    "url": "https://rabbitmq.internal.com:15672/api/healthchecks/node",
    "testName": "RabbitMQ",
    "timeoutSeconds": 15,
    "httpMethod": "GET",
    "headers": {
      "Authorization": "Basic dXNlcjpwYXNz"
    }
  }
]
```

### Private Azure Services Monitoring

```json
[
  {
    "url": "https://myapp.privatelink.azurewebsites.net",
    "testName": "Private-Web-App",
    "timeoutSeconds": 30,
    "httpMethod": "GET"
  },
  {
    "url": "https://myapi.privatelink.azurewebsites.net/health",
    "testName": "Private-API-App",
    "timeoutSeconds": 30,
    "httpMethod": "GET"
  },
  {
    "url": "https://mystorage.privatelink.blob.core.windows.net",
    "testName": "Private-Storage",
    "timeoutSeconds": 20,
    "httpMethod": "HEAD"
  }
]
```

## Local Development Configuration

### local.settings.json

```json
{
  "IsEncrypted": false,
  "Values": {
    "AzureWebJobsStorage": "UseDevelopmentStorage=true",
    "FUNCTIONS_WORKER_RUNTIME": "dotnet-isolated",
    "APPLICATIONINSIGHTS_CONNECTION_STRING": "InstrumentationKey=your-key-here",
    "PROBE_URLS": "[\"https://www.microsoft.com\", \"https://www.azure.com\"]",
    "PROBE_FREQUENCY": "0 */1 * * * *",
    "PROBE_TIMEOUT_SECONDS": "30",
    "TEST_NAME_PREFIX": "Local-Test",
    "TEST_LOCATION": "Local-Development"
  }
}
```

## Environment-Specific Configurations

### Development

- **Frequency**: Every 5 minutes
- **Timeout**: 30 seconds
- **Targets**: Development endpoints
- **Alerts**: Disabled or low priority

### Staging

- **Frequency**: Every 3 minutes
- **Timeout**: 45 seconds
- **Targets**: Staging endpoints mirroring production
- **Alerts**: Medium priority

### Production

- **Frequency**: Every 1-2 minutes
- **Timeout**: 60 seconds
- **Targets**: Production endpoints
- **Alerts**: High priority with immediate notification

## Best Practices

1. **Timeout Configuration**: Set timeouts appropriate to your service SLA
2. **Frequency**: Balance between detection speed and cost
3. **Test Names**: Use descriptive names for easy identification
4. **Location**: Use meaningful location identifiers for multi-region deployments
5. **Headers**: Secure API keys and tokens using Azure Key Vault references
6. **HTTP Methods**: Use HEAD requests for simple connectivity checks to reduce load
7. **Monitoring**: Set up alerts based on availability test results in Application Insights
