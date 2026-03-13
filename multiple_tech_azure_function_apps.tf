#terraform {
#  required_providers {
#    azurerm = {
#      source  = "hashicorp/azurerm"
#      version = "~> 3.0"
#    }
#  }
#}

#provider "azurerm" {
#  features {}
#}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "East US"
}

##############

resource "azurerm_resource_group" "functions" {
  name     = "rg-functions-prod-eus"
  location = var.location

  tags = {
    Environment = "production"
    Service     = "serverless"
  }
}

# Storage account required by Azure Functions runtime
resource "azurerm_storage_account" "functions" {
  name                     = "stfuncsprodeus"
  resource_group_name      = azurerm_resource_group.functions.name
  location                 = azurerm_resource_group.functions.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  # Minimum TLS version
  min_tls_version = "TLS1_2"

  tags = {
    Environment = "production"
    Purpose     = "function-app-storage"
  }
}

# Application Insights for monitoring
resource "azurerm_application_insights" "functions" {
  name                = "ai-functions-prod"
  location            = azurerm_resource_group.functions.location
  resource_group_name = azurerm_resource_group.functions.name
  application_type    = "web"

  tags = {
    Environment = "production"
  }
}


#################

# Consumption plan (serverless)
resource "azurerm_service_plan" "consumption" {
  name                = "asp-func-consumption"
  location            = azurerm_resource_group.functions.location
  resource_group_name = azurerm_resource_group.functions.name
  os_type             = "Linux"
  sku_name            = "Y1"  # Y1 = Consumption plan

  tags = {
    Environment = "production"
    Plan        = "consumption"
  }
}

# Linux Function App on consumption plan (Node.js)
resource "azurerm_linux_function_app" "api" {
  name                = "func-api-prod"
  location            = azurerm_resource_group.functions.location
  resource_group_name = azurerm_resource_group.functions.name
  service_plan_id     = azurerm_service_plan.consumption.id

  storage_account_name       = azurerm_storage_account.functions.name
  storage_account_access_key = azurerm_storage_account.functions.primary_access_key

  # HTTPS only
  https_only = true

  site_config {
    # Runtime stack configuration
    application_stack {
      node_version = "20"
    }

    # CORS settings for API functions
    cors {
      allowed_origins     = ["https://www.example.com", "https://app.example.com"]
      support_credentials = true
    }

    # Application Insights integration
    application_insights_key               = azurerm_application_insights.functions.instrumentation_key
    application_insights_connection_string = azurerm_application_insights.functions.connection_string
  }

  # Application settings (environment variables)
  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME" = "node"
    "WEBSITE_RUN_FROM_PACKAGE" = "1"
    "NODE_ENV"                 = "production"
  }

  # Managed identity for accessing other Azure services
  identity {
    type = "SystemAssigned"
  }

  tags = {
    Environment = "production"
    Runtime     = "nodejs"
  }
}


########

# Premium (Elastic) plan
resource "azurerm_service_plan" "premium" {
  name                = "asp-func-premium"
  location            = azurerm_resource_group.functions.location
  resource_group_name = azurerm_resource_group.functions.name
  os_type             = "Linux"
  sku_name            = "EP1"  # EP1 = Elastic Premium

  tags = {
    Environment = "production"
    Plan        = "premium"
  }
}

# Premium function app with VNet integration
resource "azurerm_linux_function_app" "processor" {
  name                = "func-processor-prod"
  location            = azurerm_resource_group.functions.location
  resource_group_name = azurerm_resource_group.functions.name
  service_plan_id     = azurerm_service_plan.premium.id

  storage_account_name       = azurerm_storage_account.functions.name
  storage_account_access_key = azurerm_storage_account.functions.primary_access_key

  https_only = true

  site_config {
    application_stack {
      python_version = "3.11"
    }

    # Pre-warmed instances for fast startup
    pre_warmed_instance_count = 1

    # Elastic scale limits
    elastic_instance_minimum = 1

    application_insights_key               = azurerm_application_insights.functions.instrumentation_key
    application_insights_connection_string = azurerm_application_insights.functions.connection_string

    # VNet route all traffic
    vnet_route_all_enabled = true
  }

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME" = "python"
    "WEBSITE_RUN_FROM_PACKAGE" = "1"
  }

  # VNet integration for private resource access
  #virtual_network_subnet_id = var.integration_subnet_id

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Environment = "production"
    Runtime     = "python"
  }
}

#variable "integration_subnet_id" {
#  description = "Subnet ID for VNet integration"
#  type        = string
#  default     = ""
#}


##########

# Dedicated App Service Plan
resource "azurerm_service_plan" "dedicated" {
  name                = "asp-func-dedicated"
  location            = azurerm_resource_group.functions.location
  resource_group_name = azurerm_resource_group.functions.name
  os_type             = "Linux"
  sku_name            = "P1v3"

  tags = {
    Environment = "production"
  }
}

# Function app on dedicated plan (.NET)
resource "azurerm_linux_function_app" "dotnet_func" {
  name                = "func-dotnet-prod"
  location            = azurerm_resource_group.functions.location
  resource_group_name = azurerm_resource_group.functions.name
  service_plan_id     = azurerm_service_plan.dedicated.id

  storage_account_name       = azurerm_storage_account.functions.name
  storage_account_access_key = azurerm_storage_account.functions.primary_access_key

  https_only = true

  site_config {
    always_on = true  # Always on is available on dedicated plans

    application_stack {
      dotnet_version              = "8.0"
      use_dotnet_isolated_runtime = true
    }

    application_insights_key               = azurerm_application_insights.functions.instrumentation_key
    application_insights_connection_string = azurerm_application_insights.functions.connection_string
  }

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME" = "dotnet-isolated"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Environment = "production"
    Runtime     = "dotnet"
  }
}




###########

# Service Bus namespace for queue triggers
resource "azurerm_servicebus_namespace" "functions" {
  name                = "sb-functions-prod"
  location            = azurerm_resource_group.functions.location
  resource_group_name = azurerm_resource_group.functions.name
  sku                 = "Standard"

  tags = {
    Environment = "production"
  }
}

# Queue for function triggers
resource "azurerm_servicebus_queue" "orders" {
  name         = "orders-queue"
  namespace_id = azurerm_servicebus_namespace.functions.id

  # Enable dead-lettering for failed messages
  dead_lettering_on_message_expiration = true
  max_delivery_count                   = 5
}

# Event Hub namespace for high-throughput event processing
resource "azurerm_eventhub_namespace" "functions" {
  name                = "eh-functions-prod"
  location            = azurerm_resource_group.functions.location
  resource_group_name = azurerm_resource_group.functions.name
  sku                 = "Standard"
  capacity            = 1

  tags = {
    Environment = "production"
  }
}

resource "azurerm_eventhub" "events" {
  name                = "app-events"
  namespace_name      = azurerm_eventhub_namespace.functions.name
  resource_group_name = azurerm_resource_group.functions.name
  partition_count     = 4
  message_retention   = 7
}

# Add connection strings to function app settings
resource "azurerm_linux_function_app" "event_processor" {
  name                = "func-events-prod"
  location            = azurerm_resource_group.functions.location
  resource_group_name = azurerm_resource_group.functions.name
  service_plan_id     = azurerm_service_plan.consumption.id

  storage_account_name       = azurerm_storage_account.functions.name
  storage_account_access_key = azurerm_storage_account.functions.primary_access_key

  site_config {
    application_stack {
      node_version = "20"
    }

    application_insights_key               = azurerm_application_insights.functions.instrumentation_key
    application_insights_connection_string = azurerm_application_insights.functions.connection_string
  }

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME"   = "node"
    "ServiceBusConnection"       = azurerm_servicebus_namespace.functions.default_primary_connection_string
    "EventHubConnection"         = azurerm_eventhub_namespace.functions.default_primary_connection_string
    "WEBSITE_RUN_FROM_PACKAGE"   = "1"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Environment = "production"
    Purpose     = "event-processing"
  }
}

#######

# Staging slot for the API function app
resource "azurerm_linux_function_app_slot" "staging" {
  name                 = "staging"
  function_app_id      = azurerm_linux_function_app.api.id
  storage_account_name = azurerm_storage_account.functions.name

  site_config {
    application_stack {
      node_version = "20"
    }

    application_insights_key               = azurerm_application_insights.functions.instrumentation_key
    application_insights_connection_string = azurerm_application_insights.functions.connection_string
  }

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME" = "node"
    "WEBSITE_RUN_FROM_PACKAGE" = "1"
    "NODE_ENV"                 = "staging"
  }

  tags = {
    Environment = "staging"
  }
}

#########

output "api_function_url" {
  description = "URL of the API function app"
  value       = "https://${azurerm_linux_function_app.api.default_hostname}"
}

output "function_app_identity" {
  description = "Principal ID of the function app managed identity"
  value       = azurerm_linux_function_app.api.identity[0].principal_id
}

output "app_insights_key" {
  description = "Application Insights instrumentation key"
  value       = azurerm_application_insights.functions.instrumentation_key
  sensitive   = true
}

