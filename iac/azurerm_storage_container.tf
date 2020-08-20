resource "azurerm_storage_container" "squassina" {
  # for_each              = var.tables
  # name                  = "${replace(lower(each.key), "_", "-")}-container"
  name                  = "st${var.prefix}-container"
  storage_account_name  = azurerm_storage_account.squassina.name
  container_access_type = "private"
}

output "container" {
  value = azurerm_storage_container.squassina.name
}