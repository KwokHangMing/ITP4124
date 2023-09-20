# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0.2"
    }
  }

  required_version = ">= 1.1.0"
}

provider "azurerm" {
  features {}
}
# Task 0
resource "azurerm_resource_group" "rg" {
  name     = "projProd"
  location = "eastasia"
}

resource "azurerm_storage_account" "example" {
  name                     = "usage"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    environment = "StaticWeb"
  }

  static_website {
    index_document = "index.html"
    error_404_document = "error.html"
  }
  
  depends_on = [azurerm_resource_group.rg]
}


resource "azurerm_storage_container" "example" {
  name                  = "$web"
  storage_account_name  = azurerm_storage_account.example.name
  container_access_type = "blob"
}

resource "azurerm_storage_blob" "example_index" {
  name                   = "index.html"
  storage_account_name   = azurerm_storage_account.example.name
  storage_container_name = azurerm_storage_container.example.name
  type                   = "Block"
  content_type           = "text/html"
  source_content         = "This is index page."
}

resource "azurerm_storage_blob" "example_error" {
  name                   = "error.html"
  storage_account_name   = azurerm_storage_account.example.name
  storage_container_name = azurerm_storage_container.example.name
  type                   = "Block"
  content_type           = "text/html"
  source_content         = "This is error page."
}