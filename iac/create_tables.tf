resource "null_resource" "create_table" {
  depends_on = [azurerm_kusto_database.squassina]
  provisioner "local-exec" {
    command     = "../scripts/py_create_tables.sh"
    interpreter = ["/bin/bash", "-c"]
    environment = {
      cluster  = azurerm_kusto_cluster.squassina.name
      location = azurerm_kusto_cluster.squassina.location
      database = azurerm_kusto_database.squassina.name
    }
  }
}