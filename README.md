# Azure Samples - App Insights Availability Agent for private IP endpoints

This is containerized Azure Functions App and Function which used Azure Applicatiion Insights SDK and emulates the same functionality of standard Application Insights availability agent which supports only Public Endpoints.
The Function App uses VNET Integration in order to be able to probe private endpoints (IPs).
The code is separated into Infra and App nlocks. "Infra" contains Terraform based deployment of all required Azure Resources. The Terraform code uses Azure Verified Modules.
"App" folder contains Function App and Function definition.
All URLs are parametrized and parameters can be injected with container environment variables.
GitHub Actions builds, tests and deploys the whole solutions (infra and app) with a single Actions pipeline. The pipeline publishes a package - built container deployable to Function App.
