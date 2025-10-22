# Get current client configuration (service principal)
data "azurerm_client_config" "current" {}

locals {
  resource_name = "${var.project_name}-${var.environment}"
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "rg-${local.resource_name}"
  location = var.location
  tags     = var.tags
}

# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "main" {
  name                = "log-${local.resource_name}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}

# Application Insights
resource "azurerm_application_insights" "main" {
  name                = "appi-${local.resource_name}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  workspace_id        = azurerm_log_analytics_workspace.main.id
  application_type    = "web"
  tags                = var.tags
}

# Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = "vnet-${local.resource_name}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = var.vnet_address_space
  tags                = var.tags
}

# Subnet for Function App VNET Integration
resource "azurerm_subnet" "function" {
  name                 = "snet-function"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = var.function_subnet_address_prefix

  delegation {
    name = "delegation"

    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

# Container Registry
resource "azurerm_container_registry" "main" {
  name                = "acr${replace(local.resource_name, "-", "")}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Basic"
  admin_enabled       = false  # Disable admin account, use RBAC only
  tags                = var.tags
}

# Assign AcrPush role to the service principal for CI/CD
resource "null_resource" "acr_rbac_sp" {
  provisioner "local-exec" {
    command = <<-EOT
      az role assignment create \
        --role "AcrPush" \
        --assignee-object-id ${data.azurerm_client_config.current.object_id} \
        --assignee-principal-type ServicePrincipal \
        --scope ${azurerm_container_registry.main.id} || true
    EOT
  }

  depends_on = [azurerm_container_registry.main]
}

# Storage Account for Function App
# Storage account created via Azure CLI to bypass policy restrictions on key-based auth
# The subscription policy blocks Terraform's validation attempts using storage keys
resource "null_resource" "storage_account" {
  provisioner "local-exec" {
    command = <<-EOT
      az storage account create \
        --name st${replace(local.resource_name, "-", "")} \
        --resource-group ${azurerm_resource_group.main.name} \
        --location ${azurerm_resource_group.main.location} \
        --sku Standard_LRS \
        --kind StorageV2 \
        --allow-shared-key-access false \
        --default-action Allow \
        --tags Environment=dev ManagedBy=Terraform Project=AvailabilityAgent
    EOT
  }

  depends_on = [azurerm_resource_group.main]
}

# Data source to reference the CLI-created storage account
data "azurerm_storage_account" "function" {
  name                = "st${replace(local.resource_name, "-", "")}"
  resource_group_name = azurerm_resource_group.main.name
  
  depends_on = [null_resource.storage_account]
}

# Assign RBAC roles to Function App managed identity using Azure CLI
# SP now has elevated permissions (User Access Administrator role)
resource "null_resource" "function_storage_rbac" {
  provisioner "local-exec" {
    command = <<-EOT
      # Wait for Function App to be created and have managed identity
      sleep 30
      
      # Get Function App principal ID
      PRINCIPAL_ID=$(az functionapp identity show \
        --name ${azurerm_linux_function_app.main.name} \
        --resource-group ${azurerm_resource_group.main.name} \
        --query principalId -o tsv)
      
      STORAGE_ID=$(az storage account show \
        --name st${replace(local.resource_name, "-", "")} \
        --resource-group ${azurerm_resource_group.main.name} \
        --query id -o tsv)
      
      # Assign roles for storage access
      az role assignment create \
        --role "Storage Blob Data Owner" \
        --assignee $PRINCIPAL_ID \
        --assignee-object-id $PRINCIPAL_ID \
        --assignee-principal-type ServicePrincipal \
        --scope $STORAGE_ID || true
      
      az role assignment create \
        --role "Storage Queue Data Contributor" \
        --assignee $PRINCIPAL_ID \
        --assignee-object-id $PRINCIPAL_ID \
        --assignee-principal-type ServicePrincipal \
        --scope $STORAGE_ID || true
      
      az role assignment create \
        --role "Storage Table Data Contributor" \
        --assignee $PRINCIPAL_ID \
        --assignee-object-id $PRINCIPAL_ID \
        --assignee-principal-type ServicePrincipal \
        --scope $STORAGE_ID || true
      
      # Assign AcrPull role for container image access
      az role assignment create \
        --role "AcrPull" \
        --assignee $PRINCIPAL_ID \
        --assignee-object-id $PRINCIPAL_ID \
        --assignee-principal-type ServicePrincipal \
        --scope ${azurerm_container_registry.main.id} || true
    EOT
  }

  depends_on = [
    azurerm_linux_function_app.main,
    null_resource.storage_account,
    azurerm_container_registry.main
  ]
}

# App Service Plan (Linux)
resource "azurerm_service_plan" "main" {
  name                = "asp-${local.resource_name}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  os_type             = "Linux"
  sku_name            = "B1"  # Changed from P1v2 to B1 (Basic tier) due to quota limits
  tags                = var.tags
}

# Linux Function App with Container
resource "azurerm_linux_function_app" "main" {
  name                = "func-${local.resource_name}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  service_plan_id     = azurerm_service_plan.main.id

  storage_account_name              = data.azurerm_storage_account.function.name
  storage_uses_managed_identity     = true  # Use managed identity for storage access

  virtual_network_subnet_id = azurerm_subnet.function.id

  site_config {
    always_on = true

    application_insights_connection_string = azurerm_application_insights.main.connection_string
    application_insights_key               = azurerm_application_insights.main.instrumentation_key

    # Container configuration with managed identity for ACR
    application_stack {
      docker {
        registry_url = "https://${azurerm_container_registry.main.login_server}"
        image_name   = var.container_image != "" ? split("/", var.container_image)[1] : "availabilityagent"
        image_tag    = var.container_image != "" ? split(":", var.container_image)[1] : "latest"
      }
    }

    container_registry_use_managed_identity = true
    vnet_route_all_enabled                  = true
  }

  app_settings = {
    "APPLICATIONINSIGHTS_CONNECTION_STRING"        = azurerm_application_insights.main.connection_string
    "PROBE_URLS"                                   = var.probe_urls
    "PROBE_FREQUENCY"                              = var.probe_frequency
    "PROBE_TIMEOUT_SECONDS"                        = tostring(var.probe_timeout_seconds)
    "TEST_NAME_PREFIX"                             = var.test_name_prefix
    "TEST_LOCATION"                                = var.test_location
    "DOCKER_REGISTRY_SERVER_URL"                   = "https://${azurerm_container_registry.main.login_server}"
    "DOCKER_ENABLE_CI"                             = "true"
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE"          = "false"
    "AzureWebJobsStorage__accountName"             = data.azurerm_storage_account.function.name  # For managed identity
  }

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags

  depends_on = [
    azurerm_container_registry.main,
    azurerm_subnet.function,
    null_resource.storage_account
  ]
}

# Note: Role assignments for storage access are handled via Azure CLI
# in null_resource.function_storage_rbac to work around RBAC permission limitations
