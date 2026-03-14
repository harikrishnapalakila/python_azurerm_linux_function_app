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


############ AI - user roles - RBAC #######################


## 1. Define the role assignment for the service principal
#resource "azurerm_role_assignment" "ai_user" {
#  scope                = azurerm_ai_foundry_project.project.id
#  role_definition_name = "Azure AI User"
#  #principal_id         = var.service_principal_object_id # Use the Object ID, not Client ID
#  principal_id         = "2eabbcee-2617-4adb-9885-43413d46c33f"
#  
#  # Recommended for service principals to avoid replication delay errors
#  skip_service_principal_aad_check = true
#}

## 2. If the Project uses a Managed Identity, it also needs access to the Hub
#resource "azurerm_role_assignment" "project_identity_on_hub" {
#  scope                = azurerm_ai_foundry.hub.id
#  role_definition_name = "Azure AI User"
#  #principal_id         = azurerm_ai_foundry_project.project.identity[0].principal_id
#  principal_id         = "2eabbcee-2617-4adb-9885-43413d46c33f"
#}



## Assign the Azure AI User role to the Project
#resource "azurerm_role_assignment" "ai_user_project" {
#  scope                = azurerm_ai_foundry_project.project.id
#  role_definition_name = "Azure AI User"
#  #principal_id         = "your-service-principal-object-id" 
#  principal_id         = "2eabbcee-2617-4adb-9885-43413d46c33f"
#  
#  # Prevents failure if the principal is not yet fully propagated in Entra ID
#  skip_service_principal_aad_check = true
#}




################### Fetch the existing AI Foundry Project ###############################

# 1. Fetch the existing AI Foundry Project
#data "azurerm_ai_foundry_project" "existing_project" {
#  name                = "ai-project-ai-agent"
#  resource_group_name = "RG-ai-agent-ai-foundry-resourcegroup"
#}

# 2. Reference the ID as the parent_id
#resource "azapi_resource" "search_connection" {
 # type      = "Microsoft.MachineLearningServices/workspaces/connections@2025-12-01"
 # name      = "search-service-connection"
#  parent_id = data.azurerm_ai_foundry_project.existing_project.id
#}



variable "project_name" {
  type        = string
  description = "The friendly name of your AI Foundry Project"
  default     = "ai-project-ai-agent"
}

variable "ai_foundry_host" {
  type        = string
  description = "The regional discovery URL (e.g. eastus.api.azureml.ms) without https://"
  default     = "eastus.api.azureml.ms"
}


######### Azure Research-AI-Agent ################

resource "azapi_data_plane_resource" "Research-Ai-Agent" {
  # This is the ONLY type that currently supports Foundry Agents
  type      = "Microsoft.AIFoundry/agents/assistants@v1"
  name      = "Assistant-Ai-Agent"
  
  # Format: [Hostname]/api/projects/[ProjectName]
  # We use replace to ensure the hostname is clean
  parent_id = "${replace(azurerm_ai_foundry.hub.discovery_url, "https://", "")}/api/projects/${azurerm_ai_foundry_project.project.name}"

  # CRITICAL: Bypasses the 'no Host' and 'type not found' validation bugs
  schema_validation_enabled = false

  body = {
    model        = "gpt-4o"
    name         = "Research-ai-agent"
    instructions = "You are a helpful customer support assistant."
    tools = [
      {
        type = "code_interpreter"
      }
    ]
  }

  depends_on = [azurerm_ai_foundry_project.project]
}



########## Azure Assistant-Ai-Agent  ############


resource "azapi_resource" "Assistant-Ai-Agent" {
  # Standard ARM Management Plane type
  #type      = "Microsoft.CognitiveServices/accounts/projects/assistants@2024-05-01-preview"
  #type      = "Microsoft.CognitiveServices/accounts/projects/assistants@2025-10-01-preview"
  type      = "Microsoft.MachineLearningServices/workspaces/assistants@2024-04-01-preview"
  #type      = "Microsoft.MachineLearningServices/workspaces/assistants@2025-12-01"
  name      = "Assistant-Ai-Agent"
  
  # Valid ARM Resource ID (starts with /subscriptions/...)
  parent_id = azurerm_ai_foundry_project.project.id

  body = {
    properties = {
      model        = "gpt-4o"
      name         = "Assistant-ai-agent"
      instructions = "You are a helpful customer support assistant."
      tools = [
        {
          type = "code_interpreter"
        }
      ]
    }
  }

  # Disables local regex checks that cause "parent_id is invalid"
  schema_validation_enabled = false
}



########## Azure AI Agent ##################
#3. Create the AI Agent (Assistant) - support-Agent - 
# Enable Code Interpreter - ai agent

#resource "azapi_data_plane_resource" "ai_agent" 
resource "azapi_data_plane_resource" "ai_agent" {
  name         = "support-agent" # Display name  
  type      = "Microsoft.AIFoundry/agents/assistants@v1"
  # The parent_id points to the project's data plane endpoint
  #parent_id  = azurerm_ai_foundry_project.project.id
  #parent_id  = data.azurerm_ai_foundry_project.existing_project.id
  #parent_id = "${azurerm_ai_foundry_project.project.id}/api" 
  #parent_id = "${azurerm_ai_foundry_project.project.endpoint}/api"
  #parent_id = "${azurerm_ai_foundry.hub.discovery_url}/api/projects/${azurerm_ai_foundry_project.project.name}"
  #parent_id = "${azurerm_ai_foundry.hub.discovery_url}/api/projects/${azurerm_ai_foundry_project.project.id}"
  #parent_id = "${trimprefix(azurerm_ai_foundry.hub.discovery_url, "https://")}/api/projects/${azurerm_ai_foundry_project.project.name}"
  #parent_id = "${trimprefix(azurerm_ai_foundry.hub.discovery_url, "https://")}/api/projects/${azurerm_ai_foundry_project.project.name}"
  #host = trim(trimprefix(azurerm_ai_foundry.hub.discovery_url, "https://"), "/")
  #parent_id = "/api/projects/${azurerm_ai_foundry_project.project.name}"
  # We combine the clean host and path into one string.
  # replace() ensures no "https://" and no trailing "/" disrupt the "Host" parsing.
  #parent_id = "${replace(azurerm_ai_foundry.hub.discovery_url, "https://", "")}/api/projects/${azurerm_ai_foundry_project.project.name}"
  
# The provider requires: [HOSTNAME]/[PATH]
  # We use replace to strip 'https://' and ensure no double slashes
  #parent_id = "${replace(azurerm_ai_foundry.hub.discovery_url, "https://", "")}/api/projects/${azurerm_ai_foundry_project.project.name}"
  #parent_id = "${var.ai_foundry_host}/api/projects/${var.project_name}"
  #parent_id = "eastus.api.azureml.ms/api/projects/ai-project-ai-agent"
  #parent_id = "https://eastus.api.azureml.ms"
   parent_id = azurerm_ai_foundry_project.project.id


  # IMPORTANT: Disable schema validation for this resource to bypass the 'Host' check bug
  #schema_validation_enabled = false

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

  # Ensure the project is fully ready
  depends_on = [azurerm_ai_foundry_project.project]
  #response_export_values = ["id", "name"]
}

output "agent_id" {
    # This will correctly return the server-generated "asst_..." ID
  value = azapi_data_plane_resource.ai_agent.name # This returns the 'asst_...' ID
  #value = azapi_resource.ai_agent.name # This returns the 'asst_...' ID
}

########## Step A: Enable Azure AI Search (Knowledge Base) for RAG ############

resource "azapi_resource" "search_connection" {
  type      = "Microsoft.CognitiveServices/accounts/projects/connections@2025-07-01-preview"  #The supported versions are [2025-04-01-preview, 2025-06-01, 2025-07-01-preview, 2025-09-01, 2025-10-01-preview].
  # You can try to update `azapi` provider to the latest version or disable the validation using the feature flag `schema_validation_enabled = false` within the resource block
  
  
  # FIX: Use the MachineLearningServices namespace to match your project's provider
  #type      = "Microsoft.MachineLearningServices/workspaces/connections@2024-04-01-preview"
  #type      = "Microsoft.MachineLearningServices/workspaces/connections@2025-10-01-preview" #The supported versions are [2020-06-01, 2020-08-01, 2020-09-01-preview, 2021-01-01, 2021-03-01-preview, 2021-04-01, 2021-07-01, 2022-01-01-preview, 2022-02-01-preview, 2022-05-01, 2022-06-01-preview, 2022-10-01, 2022-10-01-preview, 2022-12-01-preview, 2023-02-01-preview, 2023-04-01, 2023-04-01-preview, 2023-06-01-preview, 2023-08-01-preview, 2023-10-01, 2024-01-01-preview, 2024-04-01, 2024-04-01-preview, 2024-07-01-preview, 2024-10-01, 2024-10-01-preview, 2025-01-01-preview, 2025-04-01, 2025-04-01-preview, 2025-06-01, 2025-07-01-preview, 2025-09-01, 2025-10-01-preview].

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
  parent_id  = azurerm_ai_foundry_project.project.id
  #parent_id = "${azurerm_ai_foundry_project.project.endpoint}/api"
  #parent_id = "${azurerm_ai_foundry.hub.discovery_url}/api/projects/${azurerm_ai_foundry_project.project.name}"
  #parent_id = "${azurerm_ai_foundry.hub.discovery_url}/api/projects/${azurerm_ai_foundry_project.project.id}"
  #parent_id = "${trimprefix(azurerm_ai_foundry.hub.discovery_url, "https://")}/api/projects/${azurerm_ai_foundry_project.project.name}"
  #host = trim(trimprefix(azurerm_ai_foundry.hub.discovery_url, "https://"), "/")
  #parent_id = "/api/projects/${azurerm_ai_foundry_project.project.name}"
   # We combine the clean host and path into one string.
  # replace() ensures no "https://" and no trailing "/" disrupt the "Host" parsing.
  #parent_id = "${replace(azurerm_ai_foundry.hub.discovery_url, "https://", "")}/api/projects/${azurerm_ai_foundry_project.project.name}"
  # We combine the clean host and path into one string.
  # replace() ensures no "https://" and no trailing "/" disrupt the "Host" parsing.
  #parent_id = "${replace(azurerm_ai_foundry.hub.discovery_url, "https://", "")}/api/projects/${azurerm_ai_foundry_project.project.name}"

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

