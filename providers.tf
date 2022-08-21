# Set required providers and versions
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 2.29.0"
    }

    random = {
      source  = "hashicorp/random"
      version = ">= 3.0.1"
    }
  }
}

# Configure Providers
provider "azurerm" {
  features {
    key_vault {
      recover_soft_deleted_key_vaults = true
      purge_soft_delete_on_destroy    = true
    }
  }
}

provider "random" {
}