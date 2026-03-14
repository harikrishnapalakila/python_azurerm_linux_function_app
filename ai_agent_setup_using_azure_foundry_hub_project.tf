########################>>>> Create Resoruce Group for AI Agent Infra Setup <<<<#####################
# 1. Resource Group
resource "azurerm_resource_group" "rg-aiagent" {
  name     = "RG-ai-agent-ai-foundry-resourcegroup"
  location = "East US"
}


########################>>> Storage account + Key vault <<<<###############################

# 1. Storage Account (Required for AI Foundry Hub)
resource "azurerm_storage_account" "sa-aiagent" {
  name                     = "stacctaiagent" # Must be globally unique, lowercase, numbers only
  resource_group_name      = azurerm_resource_group.rg-aiagent.name
  location                 = azurerm_resource_group.rg-aiagent.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Data source to get current Tenant/Object IDs for the Key Vault access policy
data "azurerm_client_config" "current" {}

# 2. Key Vault (Required for AI Foundry Hub)
resource "azurerm_key_vault" "kv-aiagent" {
  name                = "kv-foundry-ai-agent"
  location            = azurerm_resource_group.rg-aiagent.location
  resource_group_name = azurerm_resource_group.rg-aiagent.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  # Access policy allowing the deployment user to manage it
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions     = ["Get", "Create", "Delete", "List", "Update"]
    secret_permissions  = ["Get", "List", "Set", "Delete"]
    storage_permissions = ["Get", "List", "Set", "Delete"]
  }
}

########################>>>> Create AI Foundry HUB for AI Agent Infra Setup <<<<#####################
# 2. AI Foundry Hub 
# Refer to the Azure AI Foundry documentation for implementation details
resource "azurerm_ai_foundry" "hub" {
  name                = "ai-hub-ai-agent"
  location            = azurerm_resource_group.rg-aiagent.location
  resource_group_name = azurerm_resource_group.rg-aiagent.name
  #sku_name            = "S0"
  storage_account_id = azurerm_storage_account.sa-aiagent.id
  key_vault_id       = azurerm_key_vault.kv-aiagent.id
  
  identity {
    type = "SystemAssigned"
  }
}

########################>>>> Create AI Foundry HUB Project for AI Agent Infra Setup <<<<#####################
# 3. AI Foundry Hub Project 
resource "azurerm_ai_foundry_project" "project" {
  name               = "ai-project-ai-agent"
  location           = azurerm_resource_group.rg-aiagent.location
  #ai_foundry_id       = azurerm_ai_foundry.hub.id
  ai_services_hub_id = azurerm_ai_foundry.hub.id
  identity { type = "SystemAssigned" }
}



resource "azurerm_cognitive_account" "cogacctaiagent" {
  name                = "cogacctaccount-aiagent"
  location            = azurerm_resource_group.rg-aiagent.location
  resource_group_name = azurerm_resource_group.rg-aiagent.name
  kind                = "OpenAI"
  sku_name = "S0"
  tags = {
    Acceptance = "Test"
  }
}

# Deployment for OpenAI's GPT-4o in the AI Foundry Project
resource "azurerm_cognitive_deployment" "gpt4o" {
  name                 = "gpt-4o-deployment-ai-agent"
  cognitive_account_id = azurerm_cognitive_account.cogacctaiagent.id
  
  # Link to your AI Foundry Project
  #project_name         = azurerm_cognitive_account_project.example.name

  model {
    format  = "OpenAI"
    name    = "gpt-4o"
    version = "2024-11-20" # Use the latest supported version for your region
  }

  sku {
    # 'GlobalStandard' is recommended for gpt-4o to access global throughput
    name     = "GlobalStandard" 
    capacity = 10 # Units of 1,000 Tokens Per Minute (TPM)
  }

  # Optional: Standard RAI (Responsible AI) policy
  rai_policy_name = "Microsoft.Default"

   #scale {
   # type = "Standard"
  #}
}

############ Azure AI Search Service ######
resource "azurerm_search_service" "search" {
  name                = "aisearch-service-ai-agent"
  resource_group_name = azurerm_resource_group.rg-aiagent.name
  location            = azurerm_resource_group.rg-aiagent.location
  sku                 = "basic"

  # Optional: Configure capacity (not available for 'free' SKU)
  replica_count   = 1
  partition_count = 1
}


########## Azure AI Agent ##################
#3. Create the AI Agent (Assistant) - support-Agent - 
# Enable Code Interpreter - ai agent


resource "azapi_data_plane_resource" "ai_agent" {
  name         = "support-agent" # Display name  
  type      = "Microsoft.AIFoundry/agents/assistants@v1"
  # The parent_id points to the project's data plane endpoint
  #parent_id = "${azurerm_ai_foundry_project.project.id}/api" 
  #parent_id = "${azurerm_ai_foundry_project.project.endpoint}/api"
  #parent_id = "${azurerm_ai_foundry.hub.discovery_url}/api/projects/${azurerm_ai_foundry_project.project.name}"
  #parent_id = "${azurerm_ai_foundry.hub.discovery_url}/api/projects/${azurerm_ai_foundry_project.project.id}"
  parent_id = "${trimprefix(azurerm_ai_foundry.hub.discovery_url, "https://")}/api/projects/${azurerm_ai_foundry_project.project.name}"

  body = {
    model        = "gpt-4o"
    name         = "support-agent" # Display name    
    instructions = "You are a helpful customer support assistant."
  # 2.Agent - name = "data-analyst-agent"
  #  instructions = "Use python code to solve math problems and analyze data."
    tools        = [
        {
            type = "code_interpreter"
        }
    ] # Add tools like code_interpreter or functions here
  }
}

output "agent_id" {
    # This will correctly return the server-generated "asst_..." ID
  value = azapi_data_plane_resource.ai_agent.name # This returns the 'asst_...' ID
}

########## Step A: Enable Azure AI Search (Knowledge Base) for RAG ############

resource "azapi_resource" "search_connection" {
  type      = "Microsoft.CognitiveServices/accounts/projects/connections@2025-07-01-preview"  #The supported versions are [2025-04-01-preview, 2025-06-01, 2025-07-01-preview, 2025-09-01, 2025-10-01-preview].
  # You can try to update `azapi` provider to the latest version or disable the validation using the feature flag `schema_validation_enabled = false` within the resource block
  name      = "search-service-connection"
  #parent_id = azurerm_ai_foundry_project.project.id
  parent_id = azurerm_ai_foundry_project.project.id
  #parent_id = "${azurerm_ai_foundry.hub.discovery_url}/api/projects/${azurerm_ai_foundry_project.project.id}"

  #body = {
  #  properties = {
  #    connectionType = "AzureAISearch"
  #    endpoint       = "https://${azurerm_search_service.search.name}.search.windows.net"
  #    # Auth can be API Key or Managed Identity (recommended)
  #    authType       = "ApiKey" 
  #    credentials = {
  #      key = azurerm_search_service.search.primary_key
  #    }
  #  }
  #}
   body = {
    properties = {
      category      = "CognitiveSearch"
      #target        = azurerm_search_service.search.endpoint # The Search URL
      target = "https://${azurerm_search_service.search.name}.search.windows.net"
      authType      = "ApiKey"                             # Or "AAD"
      credentials = {
        key = azurerm_search_service.search.primary_key
      }
      # Metadata for the UI to recognize it as a Search connection
      metadata = {
        ApiType    = "Azure"
        ResourceId = azurerm_search_service.search.id
      }
    }
 }
}


##### Step B: Add File Search Tool to Agent ##############

resource "azapi_data_plane_resource" "ai_agent_with_search" {
    name         = "research-agent"
  type      = "Microsoft.AIFoundry/agents/assistants@v1"
  #parent_id = "${azurerm_ai_foundry_project.project.endpoint}/api"
  #parent_id = "${azurerm_ai_foundry.hub.discovery_url}/api/projects/${azurerm_ai_foundry_project.project.name}"
  #parent_id = "${azurerm_ai_foundry.hub.discovery_url}/api/projects/${azurerm_ai_foundry_project.project.id}"
  parent_id = "${trimprefix(azurerm_ai_foundry.hub.discovery_url, "https://")}/api/projects/${azurerm_ai_foundry_project.project.name}"

  body = {
    model        = "gpt-4o"
    name         = "research-agent"
    instructions = "Use the search tool to find information in uploaded documents."
    tools = [
      {
        type = "file_search"
      }
    ]
    # Optional: Link a specific vector store if you have pre-indexed data
    # tool_resources = {
    #   file_search = {
    #     vector_store_ids = ["vs_abc123"]
    #   }
    # }
  }
}
