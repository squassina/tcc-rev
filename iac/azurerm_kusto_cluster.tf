resource "azurerm_kusto_cluster" "squassina" {
  name                    = "adx${replace(var.prefix, "-", "")}"
  location                = azurerm_resource_group.squassina.location
  resource_group_name     = azurerm_resource_group.squassina.name
  language_extensions     = ["PYTHON", "R"]
  enable_streaming_ingest = true

  sku {
    name     = "Standard_D13_v2"
    capacity = 2
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Environment = var.environment
  }
}

output "cluster" {
  value = azurerm_kusto_cluster.squassina.name
}

output "uri" {
  value = azurerm_kusto_cluster.squassina.uri
}

output "data_ingestion_uri" {
  value = azurerm_kusto_cluster.squassina.data_ingestion_uri
}
 