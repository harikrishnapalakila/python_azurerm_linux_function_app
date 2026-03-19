# Resource Group
resource "azurerm_resource_group" "RG-cosmosdb" {
  name     = "RG-cosmosdb"
  location = "East US"
}

# Cosmos DB Account
resource "azurerm_cosmosdb_account" "account-cosmosdb" {
  name                = "acct-cosmos-db"
  location            = azurerm_resource_group.RG-cosmosdb.location
  resource_group_name = azurerm_resource_group.RG-cosmosdb.name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB" # Use MongoDB or Parse for other APIs

  consistency_policy {
    consistency_level       = "Session"
    max_interval_in_seconds = 5
    max_staleness_prefix    = 100
  }

  geo_location {
    location          = azurerm_resource_group.RG-cosmosdb.location
    failover_priority = 0
  }

  capabilities {
    name = "EnableServerless" # Change to Provisioned if preferred
  }
}

# SQL Database
resource "azurerm_cosmosdb_sql_database" "cosmosdb-sql-db" {
  name                = "cosmosdb-sql-db"
  resource_group_name = azurerm_cosmosdb_account.account-cosmosdb.resource_group_name
  account_name        = azurerm_cosmosdb_account.account-cosmosdb.name
}

# SQL Container
resource "azurerm_cosmosdb_sql_container" "example" {
  name                = "cosmosdb-sql-container"
  resource_group_name = azurerm_cosmosdb_account.account-cosmosdb.resource_group_name
  account_name        = azurerm_cosmosdb_account.account-cosmosdb.name
  database_name       = azurerm_cosmosdb_sql_database.cosmosdb-sql-db.name
  partition_key_paths  = ["/id"]
}
