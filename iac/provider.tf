provider "azurerm" {
  version = "~> 2.19"
  features {
    #   key_vault {
    #     purge_soft_delete_on_destroy    = true
    #     recover_soft_deleted_key_vaults = true
    #   }
  }
}

# provider "azuread" {
#   version = "~> 0.11"
# }

provider "random" {
  version = "~> 2.3"
}

provider "null" {
  version = "~> 2.1"
}
