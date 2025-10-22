# Deployment Guide

## Prerequisites

1. **Azure Subscription** with permissions to create resources
2. **Azure CLI** installed and configured
3. **Terraform** >= 1.6 installed
4. **Docker** installed (for local testing)
5. **.NET 8 SDK** installed
6. **GitHub** account with repository

## GitHub Secrets Configuration

Configure the following secrets in your GitHub repository (Settings > Secrets and variables > Actions):

### Required Secrets

1. **AZURE_CREDENTIALS**: Service Principal credentials in JSON format
   ```json
   {
     "clientId": "<client-id>",
     "clientSecret": "<client-secret>",
     "subscriptionId": "<subscription-id>",
     "tenantId": "<tenant-id>"
   }
   ```

   Create the Service Principal:
   ```bash
   az ad sp create-for-rbac --name "github-actions-availagent" \
     --role Contributor \
     --scopes /subscriptions/<subscription-id> \
     --sdk-auth
   ```

2. **ACR_LOGIN_SERVER**: Azure Container Registry login server (e.g., `acravailagentdev123456.azurecr.io`)
3. **ACR_USERNAME**: ACR admin username
4. **ACR_PASSWORD**: ACR admin password

> Note: ACR credentials will be available after the first Terraform deployment.

## Initial Deployment

### Step 1: Configure Terraform Variables

1. Copy the example file:
   ```bash
   cd infra
   cp terraform.tfvars.example terraform.tfvars
   ```

2. Edit `terraform.tfvars` with your configuration:
   - Update `location` to your preferred Azure region
   - Configure `probe_urls` with your private endpoints
   - Adjust other settings as needed

### Step 2: Deploy Infrastructure Manually (First Time)

For the first deployment, deploy infrastructure manually to create the ACR:

```bash
cd infra

# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply the configuration
terraform apply
```

After deployment, note the outputs:
- Container Registry name and login server
- Function App name
- Resource Group name

### Step 3: Configure GitHub Secrets

Use the Terraform outputs to configure GitHub secrets:

```bash
# Get ACR credentials
az acr credential show --name <acr-name> --resource-group <rg-name>

# Set GitHub secrets (use GitHub CLI or web interface)
gh secret set ACR_LOGIN_SERVER --body "<acr-name>.azurecr.io"
gh secret set ACR_USERNAME --body "<acr-username>"
gh secret set ACR_PASSWORD --body "<acr-password>"
```

### Step 4: Build and Push Initial Container

```bash
cd app

# Login to ACR
az acr login --name <acr-name>

# Build and push the container
docker build -t <acr-name>.azurecr.io/availabilityagent:latest .
docker push <acr-name>.azurecr.io/availabilityagent:latest
```

### Step 5: Update Function App with Container

```bash
az functionapp config container set \
  --name <function-app-name> \
  --resource-group <rg-name> \
  --docker-custom-image-name <acr-name>.azurecr.io/availabilityagent:latest

az functionapp restart --name <function-app-name> --resource-group <rg-name>
```

### Step 6: Enable GitHub Actions

Once ACR secrets are configured, push to the `main` branch to trigger the CI/CD pipeline:

```bash
git add .
git commit -m "Initial deployment"
git push origin main
```

## Subsequent Deployments

After the initial setup, all deployments are automated through GitHub Actions:

1. Make changes to code or infrastructure
2. Commit and push to `main` branch
3. GitHub Actions will:
   - Build the .NET application
   - Create and push Docker container
   - Deploy infrastructure changes (if any)
   - Update Function App with new container

## Monitoring and Verification

### View Application Insights

1. Navigate to Azure Portal
2. Open the Application Insights resource
3. Go to **Availability** section
4. View your custom availability tests

### Check Function Logs

```bash
# Stream logs
az functionapp log tail --name <function-app-name> --resource-group <rg-name>

# Or view in Azure Portal
# Function App > Functions > AvailabilityProbeFunction > Monitor
```

### Test Locally

1. Update `local.settings.json` with your configuration
2. Run the function locally:
   ```bash
   cd app/src/AvailabilityAgent
   func start
   ```

## Configuration Reference

### Environment Variables

| Variable | Description | Default | Example |
|----------|-------------|---------|---------|
| `PROBE_URLS` | JSON array of URLs to probe | Required | `["https://api.internal.com"]` |
| `PROBE_FREQUENCY` | Cron expression for frequency | `0 */5 * * * *` | `0 */15 * * * *` (every 15 min) |
| `PROBE_TIMEOUT_SECONDS` | Request timeout in seconds | `30` | `60` |
| `TEST_NAME_PREFIX` | Prefix for test names | `Private-Endpoint` | `MyApp-Health` |
| `TEST_LOCATION` | Location identifier | `VNET-Integration` | `VNET-EastUS` |
| `APPLICATIONINSIGHTS_CONNECTION_STRING` | App Insights connection | Auto-configured | From Terraform output |

### Advanced Probe Configuration

For detailed probe configuration with custom headers and methods:

```json
[
  {
    "url": "https://api.internal.com/health",
    "testName": "API-Health-Check",
    "timeoutSeconds": 30,
    "httpMethod": "GET",
    "headers": {
      "X-Custom-Header": "value"
    }
  },
  {
    "url": "http://10.0.1.50/status",
    "testName": "Internal-Service",
    "timeoutSeconds": 15,
    "httpMethod": "POST"
  }
]
```

## Troubleshooting

### Function Not Triggering

1. Check timer trigger configuration in App Settings
2. Verify Function App is running: `az functionapp show --name <name> --resource-group <rg>`
3. Check Function App logs for errors

### Probes Failing

1. Verify VNET integration is working
2. Check if endpoints are accessible from the VNET
3. Review timeout settings
4. Check Application Insights for error details

### Container Not Updating

1. Verify ACR credentials are correct
2. Check GitHub Actions logs for build/push errors
3. Manually restart Function App
4. Verify container image tag in Function App configuration

## Cleanup

To remove all resources:

```bash
cd infra
terraform destroy
```

## Support

For issues and questions:
- Check Application Insights logs
- Review Function App logs
- Verify VNET connectivity
- Check GitHub Actions workflow logs
