terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0" # Pin to the latest major version
    }
  }
}

# The provider block is where you configure authentication and behavior
provider "azurerm" {
  # This block is REQUIRED for the Azure provider to function, 
  # even if it is left empty.
  features {}

  # Optional: Subscription details (can also be set via environment variables)
  # subscription_id = "your-subscription-id"
  # tenant_id       = "your-tenant-id"
}



resource "azurerm_resource_group" "python-linux-functionapp" {
  name     = "RG-python-linux-functionapp"
  location = "West Europe"
}

resource "azurerm_storage_account" "pythonsa" {
  name                     = "linuxfunctionappsa"
  resource_group_name      = azurerm_resource_group.python-linux-functionapp.name
  location                 = azurerm_resource_group.python-linux-functionapp.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_service_plan" "pythonserviceplan" {
  name                = "python-linux-app-service-plan"
  resource_group_name      = azurerm_resource_group.python-linux-functionapp.name
  location                 = azurerm_resource_group.python-linux-functionapp.location
  os_type             = "Linux"
  sku_name            = "B1"
}

resource "azurerm_linux_function_app" "pythonlinuxfuncationapp" {
  name                = "python-linux-function-app"
  resource_group_name      = azurerm_resource_group.python-linux-functionapp.name
  location                 = azurerm_resource_group.python-linux-functionapp.location

  storage_account_name       = azurerm_storage_account.pythonsa.name
  storage_account_access_key = azurerm_storage_account.pythonsa.primary_access_key
  service_plan_id            = azurerm_service_plan.pythonserviceplan.id

  site_config {
    application_stack {
      python_version = "3.10"
    }
}
}