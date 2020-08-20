resource "azurerm_storage_account" "squassina" {
  name                     = "st${replace(var.prefix, "-", "")}"
  location                 = var.location
  resource_group_name      = azurerm_resource_group.squassina.name
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    environment = var.environment
  }
}
