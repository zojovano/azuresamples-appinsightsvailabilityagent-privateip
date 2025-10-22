variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "eastus"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "availagent"
}

variable "probe_urls" {
  description = "JSON array of URLs to probe"
  type        = string
  default     = "[\"https://www.microsoft.com\", \"https://www.azure.com\"]"
}

variable "probe_frequency" {
  description = "Cron expression for probe frequency"
  type        = string
  default     = "0 */5 * * * *"
}

variable "probe_timeout_seconds" {
  description = "Timeout in seconds for each probe"
  type        = number
  default     = 30
}

variable "test_name_prefix" {
  description = "Prefix for test names in Application Insights"
  type        = string
  default     = "Private-Endpoint"
}

variable "test_location" {
  description = "Test location identifier"
  type        = string
  default     = "VNET-Integration"
}

variable "container_image" {
  description = "Container image for the Function App (format: registry.azurecr.io/image:tag)"
  type        = string
  default     = ""
}

variable "vnet_address_space" {
  description = "Address space for the VNet"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "function_subnet_address_prefix" {
  description = "Address prefix for Function App subnet"
  type        = list(string)
  default     = ["10.0.1.0/24"]
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "AvailabilityAgent"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}
