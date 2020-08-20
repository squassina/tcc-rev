resource "azurerm_resource_group" "squassina" {
  name     = "rg-${var.prefix}"
  location = var.location
}

