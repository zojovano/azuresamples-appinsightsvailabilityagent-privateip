# Generate random suffix for unique resource names
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

locals {
  resource_suffix = "${var.environment}-${random_string.suffix.result}"
  resource_name   = "${var.project_name}-${local.resource_suffix}"
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
  admin_enabled       = true
  tags                = var.tags
}

# Storage Account for Function App
resource "azurerm_storage_account" "function" {
  name                     = "st${replace(local.resource_name, "-", "")}"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = var.tags
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

  storage_account_name       = azurerm_storage_account.function.name
  storage_account_access_key = azurerm_storage_account.function.primary_access_key

  virtual_network_subnet_id = azurerm_subnet.function.id

  site_config {
    always_on = true

    application_insights_connection_string = azurerm_application_insights.main.connection_string
    application_insights_key               = azurerm_application_insights.main.instrumentation_key

    # Container configuration
    application_stack {
      docker {
        registry_url      = "https://${azurerm_container_registry.main.login_server}"
        image_name        = var.container_image != "" ? split("/", var.container_image)[1] : "availabilityagent"
        image_tag         = var.container_image != "" ? split(":", var.container_image)[1] : "latest"
        registry_username = azurerm_container_registry.main.admin_username
        registry_password = azurerm_container_registry.main.admin_password
      }
    }

    vnet_route_all_enabled = true
  }

  app_settings = {
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.main.connection_string
    "PROBE_URLS"                            = var.probe_urls
    "PROBE_FREQUENCY"                       = var.probe_frequency
    "PROBE_TIMEOUT_SECONDS"                 = tostring(var.probe_timeout_seconds)
    "TEST_NAME_PREFIX"                      = var.test_name_prefix
    "TEST_LOCATION"                         = var.test_location
    "DOCKER_REGISTRY_SERVER_URL"            = "https://${azurerm_container_registry.main.login_server}"
    "DOCKER_REGISTRY_SERVER_USERNAME"       = azurerm_container_registry.main.admin_username
    "DOCKER_REGISTRY_SERVER_PASSWORD"       = azurerm_container_registry.main.admin_password
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE"   = "false"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags

  depends_on = [
    azurerm_container_registry.main,
    azurerm_subnet.function
  ]
}
