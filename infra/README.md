# Infra README

This directory contains Terraform Infrastructure as Code (IaC) for deploying the Availability Agent solution.

## Resources Created

The Terraform configuration creates the following Azure resources:

1. **Resource Group** - Container for all resources
2. **Virtual Network** - Private network for Function App
3. **Subnet** - Delegated subnet for Function App VNET Integration
4. **Application Insights** - Monitoring and availability tracking
5. **Log Analytics Workspace** - Backend for Application Insights
6. **Container Registry** - Stores Docker images
7. **Storage Account** - Required for Azure Functions
8. **App Service Plan** - Linux plan for Function App
9. **Function App** - Containerized function with VNET Integration

## Prerequisites

- Azure CLI authenticated (`az login`)
- Terraform >= 1.6 installed
- Appropriate Azure subscription permissions

## Quick Start

```bash
# Copy example variables
cp terraform.tfvars.example terraform.tfvars

# Edit with your configuration
nano terraform.tfvars

# Initialize Terraform
terraform init

# Preview changes
terraform plan

# Apply configuration
terraform apply
```

## Important Variables

### Required
- `probe_urls` - JSON array of URLs to monitor

### Optional (with defaults)
- `location` - Azure region (default: "eastus")
- `environment` - Environment name (default: "dev")
- `project_name` - Project identifier (default: "availagent")
- `probe_frequency` - Cron schedule (default: "0 */5 * * * *")
- `probe_timeout_seconds` - Timeout (default: 30)
- `vnet_address_space` - VNET CIDR (default: ["10.0.0.0/16"])
- `function_subnet_address_prefix` - Subnet CIDR (default: ["10.0.1.0/24"])

## Outputs

After deployment, Terraform outputs:
- Resource Group name
- Function App name and URL
- Application Insights connection string
- Container Registry login server
- VNET and subnet IDs

## State Management

For team collaboration, consider using remote state:

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "sttfstate"
    container_name       = "tfstate"
    key                  = "availagent.tfstate"
  }
}
```

## Cost Optimization

To reduce costs in non-production environments:
- Use B1 or S1 App Service Plan SKU
- Reduce probe frequency
- Use shorter retention periods for logs

## Network Configuration

The default configuration creates:
- VNET: 10.0.0.0/16
- Function Subnet: 10.0.1.0/24

Adjust in `terraform.tfvars` if these conflict with your existing networks.

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

## Troubleshooting

### Error: Container image not found
- Deploy infrastructure first without container
- Build and push container to ACR
- Update Function App with container image

### Error: Subnet delegation conflict
- Ensure subnet is only used for Function Apps
- Check for existing delegations

### Error: Name already exists
- Resource names must be globally unique
- Modify `project_name` or `environment` variables
