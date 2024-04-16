terraform {
  required_version = ">= 1.4.5"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.48.0"
    }
    
    azapi = {
      source  = "Azure/azapi"
      version = ">= 1.4.0"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.2.1"
    }
  }

  backend "azurerm" {
        resource_group_name  = "sulaiman-test1_group"
        storage_account_name = "practicestate16042024"
        container_name       = "tfstate"
        key                  = "terraform.tfstate"
    }

}
