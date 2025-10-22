# Quick Reference Guide

Quick commands and references for the Availability Agent project.

## 📋 Prerequisites Checklist

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

## 🚀 Quick Start Commands

### Local Development

```bash
# Navigate to app
cd app/src/AvailabilityAgent

# Restore packages
dotnet restore

# Build
dotnet build

# Run locally
func start

# Test specific function
curl http://localhost:7071/admin/functions/AvailabilityProbeFunction
```

### Docker

```bash
# Build container
cd app
docker build -t availabilityagent:latest .

# Run container locally
docker run -p 8080:80 \
  -e APPLICATIONINSIGHTS_CONNECTION_STRING="your-key" \
  -e PROBE_URLS='["https://www.microsoft.com"]' \
  availabilityagent:latest

# Test container
curl http://localhost:8080
```

### Terraform

```bash
# Navigate to infra
cd infra

# Initialize
terraform init

# Format code
terraform fmt

# Validate
terraform validate

# Plan
terraform plan

# Apply
terraform apply

# Destroy
terraform destroy

# Get outputs
terraform output

# Get specific output
terraform output -raw function_app_name
```

### Azure CLI

```bash
# List Function Apps
az functionapp list --output table

# Get Function App details
az functionapp show \
  --name <function-app-name> \
  --resource-group <rg-name>

# Stream logs
az functionapp log tail \
  --name <function-app-name> \
  --resource-group <rg-name>

# Restart Function App
az functionapp restart \
  --name <function-app-name> \
  --resource-group <rg-name>

# Update container image
az functionapp config container set \
  --name <function-app-name> \
  --resource-group <rg-name> \
  --docker-custom-image-name <acr>.azurecr.io/availabilityagent:latest

# Get ACR credentials
az acr credential show \
  --name <acr-name> \
  --resource-group <rg-name>

# Login to ACR
az acr login --name <acr-name>

# List App Settings
az functionapp config appsettings list \
  --name <function-app-name> \
  --resource-group <rg-name>

# Set App Setting
az functionapp config appsettings set \
  --name <function-app-name> \
  --resource-group <rg-name> \
  --settings "PROBE_FREQUENCY=0 */10 * * * *"
```

### GitHub CLI

```bash
# Set secrets
gh secret set AZURE_CREDENTIALS < credentials.json
gh secret set ACR_LOGIN_SERVER --body "myacr.azurecr.io"
gh secret set ACR_USERNAME --body "username"
gh secret set ACR_PASSWORD --body "password"

# List secrets
gh secret list

# Trigger workflow
gh workflow run deploy.yml

# View workflow runs
gh run list

# View specific run
gh run view <run-id>
```

## 🔍 Troubleshooting Commands

### Check Function App Status

```bash
# Get Function App state
az functionapp show \
  --name <function-app-name> \
  --resource-group <rg-name> \
  --query "state" \
  --output tsv

# Check if Function is running
az functionapp function show \
  --name <function-app-name> \
  --resource-group <rg-name> \
  --function-name AvailabilityProbeFunction
```

### View Logs

```bash
# Application Insights logs query
az monitor app-insights query \
  --app <app-insights-name> \
  --analytics-query "traces | where timestamp > ago(1h) | order by timestamp desc"

# Function invocations
az monitor app-insights query \
  --app <app-insights-name> \
  --analytics-query "requests | where timestamp > ago(1h)"

# Availability tests
az monitor app-insights query \
  --app <app-insights-name> \
  --analytics-query "availabilityResults | where timestamp > ago(1h)"
```

### Network Testing

```bash
# Test from Function App
az functionapp config access-restriction show \
  --name <function-app-name> \
  --resource-group <rg-name>

# Check VNET integration
az functionapp vnet-integration list \
  --name <function-app-name> \
  --resource-group <rg-name>

# Test connectivity (using Kudu console)
# Navigate to: https://<function-app-name>.scm.azurewebsites.net/DebugConsole
# Use: curl <your-internal-endpoint>
```

## 📊 Monitoring Queries (KQL)

### Application Insights Queries

```kql
// View all availability tests
availabilityResults
| where timestamp > ago(1h)
| summarize 
    SuccessCount = countif(success == true),
    FailureCount = countif(success == false),
    AvgDuration = avg(duration)
    by name, location
| order by name

// Failed probes
availabilityResults
| where timestamp > ago(24h) and success == false
| project timestamp, name, location, message, duration

// Success rate by endpoint
availabilityResults
| where timestamp > ago(24h)
| summarize 
    Total = count(),
    Success = countif(success == true),
    SuccessRate = round(100.0 * countif(success == true) / count(), 2)
    by name
| order by SuccessRate asc

// Response time trends
availabilityResults
| where timestamp > ago(24h) and success == true
| summarize AvgDuration = avg(duration) by bin(timestamp, 5m), name
| render timechart

// Function execution logs
traces
| where message contains "Probing endpoint"
| project timestamp, message, severityLevel
| order by timestamp desc
```

## 🔐 Security

### Create Service Principal

```bash
# Create SP for GitHub Actions
az ad sp create-for-rbac \
  --name "github-actions-availagent" \
  --role Contributor \
  --scopes /subscriptions/<subscription-id> \
  --sdk-auth

# Create SP with specific permissions
az ad sp create-for-rbac \
  --name "availagent-deployer" \
  --role Contributor \
  --scopes /subscriptions/<subscription-id>/resourceGroups/<rg-name>
```

## 📝 Common Configuration Patterns

### Simple Configuration

```bash
export PROBE_URLS='["https://api.internal.com"]'
export PROBE_FREQUENCY="0 */5 * * * *"
export PROBE_TIMEOUT_SECONDS="30"
```

### Advanced Configuration

```bash
export PROBE_URLS='[
  {
    "url": "https://api.internal.com/health",
    "testName": "API-Health",
    "timeoutSeconds": 30,
    "httpMethod": "GET"
  }
]'
```

## 🎯 Cron Expression Quick Reference

| Cron | Description |
|------|-------------|
| `0 */1 * * * *` | Every 1 minute |
| `0 */5 * * * *` | Every 5 minutes |
| `0 */15 * * * *` | Every 15 minutes |
| `0 */30 * * * *` | Every 30 minutes |
| `0 0 */1 * * *` | Every hour |
| `0 0 9 * * *` | Daily at 9 AM |
| `0 0 9 * * 1-5` | Weekdays at 9 AM |

## 📦 Package Management

```bash
# Add package
dotnet add package PackageName

# Update packages
dotnet restore

# List packages
dotnet list package

# Remove package
dotnet remove package PackageName
```

## 🔄 Git Commands

```bash
# Clone repository
git clone https://github.com/zojovano/azuresamples-appinsightsvailabilityagent-privateip.git

# Create feature branch
git checkout -b feature/my-feature

# Stage changes
git add .

# Commit
git commit -m "Description of changes"

# Push
git push origin feature/my-feature

# Pull latest
git pull origin main
```

## 💡 Tips

1. **Test locally first**: Always test with `func start` before deploying
2. **Use small timeouts**: Start with 30s and increase if needed
3. **Monitor costs**: Check Azure Cost Management regularly
4. **Use tags**: Tag all resources for cost tracking
5. **Backup state**: Use remote state for Terraform
6. **Review logs**: Check Application Insights regularly
7. **Set alerts**: Configure availability alerts in App Insights
8. **Version containers**: Use specific tags, not just "latest"

## 🆘 Support Resources

- [Azure Functions Documentation](https://docs.microsoft.com/azure/azure-functions/)
- [Application Insights Documentation](https://docs.microsoft.com/azure/azure-monitor/app/app-insights-overview)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [GitHub Actions Documentation](https://docs.github.com/actions)

---

**Quick Reference Version:** 1.0
**Last Updated:** October 22, 2025
