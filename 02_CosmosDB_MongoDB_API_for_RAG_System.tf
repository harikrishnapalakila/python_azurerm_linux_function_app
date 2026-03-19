# 1. Cosmos DB Account (MongoDB Kind)
resource "azurerm_cosmosdb_account" "mongo_acc" {
  name                = "cosmos-rag-mongo-001"
  location            = "East US"
  resource_group_name = "rg-enterprise-rag"
  offer_type          = "Standard"
  kind                = "MongoDB" # Crucial change from 'GlobalDocumentDB'

  consistency_policy {
    consistency_level = "Session"
  }

  geo_location {
    location          = "East US"
    failover_priority = 0
  }

  capabilities {
    name = "EnableMongo"       # Required for Mongo API
  }
  
  capabilities {
    name = "EnableServerless"  # Optional: Great for cost-saving in dev
  }
}

# 2. MongoDB Database
resource "azurerm_cosmosdb_mongo_database" "mongodb" {
  name                = "RAGMongoDatabase"
  resource_group_name = azurerm_cosmosdb_account.mongo_acc.resource_group_name
  account_name        = azurerm_cosmosdb_account.mongo_acc.name
}

# 3. MongoDB Collection
resource "azurerm_cosmosdb_mongo_collection" "collection" {
  name                = "ChatHistory"
  resource_group_name = azurerm_cosmosdb_account.mongo_acc.resource_group_name
  account_name        = azurerm_cosmosdb_account.mongo_acc.name
  database_name       = azurerm_cosmosdb_mongo_database.mongodb.name

  default_ttl_seconds = "777"
  shard_key           = "userId" # MongoDB uses Shard Keys instead of Partition Keys

  index {
    keys   = ["_id"]
    unique = true
  }
}


#Updated Outputs for MongoDB
#The connection string format differs for MongoDB. Use this output to get the standard mongodb:// URI for your Python pymongo client:


output "cosmosdb_mongo_connection_string" {
  value     = azurerm_cosmosdb_account.mongo_acc.connection_strings[0]
  sensitive = true
}

#Python Client Change
#Since you are now using the MongoDB API, you should use the pymongo library instead of azure-cosmos:

#from pymongo import MongoClient

## Use the connection string from terraform output
#client = MongoClient(MONGO_CONNECTION_STRING)
#db = client["RAGMongoDatabase"]
#collection = db["ChatHistory"]
