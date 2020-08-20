resource "azurerm_kusto_database" "squassina" {
  name                = "adx-db-${var.prefix}"
  resource_group_name = azurerm_resource_group.squassina.name
  location            = var.location
  cluster_name        = azurerm_kusto_cluster.squassina.name

  hot_cache_period   = "P7D"
  soft_delete_period = "P31D"
}

output "database" {
  value = azurerm_kusto_database.squassina.name
}