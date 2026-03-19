#To set up Azure Cosmos DB using Terraform, you generally define a azurerm_cosmosdb_account along with the specific API resource (SQL Database/Container or MongoDB Database/Collection)
#Below is the code for the SQL (Core) API, which is the most common for RAG systems.
#Terraform Code: Cosmos DB (SQL API)


# 1. Cosmos DB Account
resource "azurerm_cosmosdb_account" "acc" {
  name                = "cosmos-rag-data-001"
  location            = "East US"
  resource_group_name = "rg-enterprise-rag"
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB" # Use 'MongoDB' for Mongo API

  consistency_policy {
    consistency_level = "Session"
  }

  geo_location {
    location          = "East US"
    failover_priority = 0
  }

  capabilities {
    name = "EnableServerless" # Recommended for dev/testing costs
  }
}

# 2. SQL Database
resource "azurerm_cosmosdb_sql_database" "db" {
  name                = "RAGDatabase"
  resource_group_name = azurerm_cosmosdb_account.acc.resource_group_name
  account_name        = azurerm_cosmosdb_account.acc.name
}

# 3. SQL Container (Table)
resource "azurerm_cosmosdb_sql_container" "container" {
  name                = "ChatHistory"
  resource_group_name = azurerm_cosmosdb_account.acc.resource_group_name
  account_name        = azurerm_cosmosdb_account.acc.name
  database_name       = azurerm_cosmosdb_sql_database.db.name
  partition_key_path  = "/userId"
  
  indexing_policy {
    indexing_mode = "consistent"
  }
}




#outputs block to automatically grab the Primary Connection String for your Python script?


#To pass these values directly into your Python environment or .env file, add this outputs.tf block to your Terraform configuration.
#This will extract the Endpoint and the Primary Master Key (which you'll need for the CosmosClient in Python).

# The Endpoint URL (e.g., https://cosmos-rag-data-001.documents.azure.com)
output "cosmosdb_endpoint" {
  value       = azurerm_cosmosdb_account.acc.endpoint
  description = "The Cosmos DB endpoint for the Python SDK."
}

# The Primary Master Key (Sensitive)
output "cosmosdb_primary_key" {
  value     = azurerm_cosmosdb_account.acc.primary_key
  sensitive = true
}

# The Primary Connection String (for MongoDB or certain App Service settings)
output "cosmosdb_connection_string" {
  value     = azurerm_cosmosdb_account.acc.primary_sql_connection_string
  sensitive = true
}


#How to view them
#Since keys are marked as sensitive, they won't show up in plain text when you run terraform apply. To see them, run:
#terraform output -json
## OR for just the key:
#terraform output -raw cosmosdb_primary_key


#Edwardjones_Enterprise_Azure_RAG_System.py

#from azure.cosmos import CosmosClient

#COSMOS_ENDPOINT = "your_output_endpoint"
#COSMOS_KEY = "your_output_key"

#client = CosmosClient(COSMOS_ENDPOINT, COSMOS_KEY)
#database = client.get_database_client("RAGDatabase")
#container = database.get_container_client("ChatHistory")
