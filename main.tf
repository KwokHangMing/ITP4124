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

resource "azurerm_storage_account" "azfunction" {
  name                     = "azfunction220011928"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = "southeastasia"
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    usage = "logic"
  }
}

resource "azurerm_storage_account" "staticweb" {
  name                     = "staticweb220011928"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  access_tier              = "Hot"

  tags = {
    usage = "StaticWeb"
  }

  static_website {
    index_document     = "index.html"
    error_404_document = "error.html"
  }
}

resource "azurerm_storage_blob" "staticweb_index" {
  name                   = "index.html"
  storage_account_name   = azurerm_storage_account.staticweb.name
  storage_container_name = "$web"
  type                   = "Block"
  content_type           = "text/html"
  source_content         = "This is index page."
}

resource "azurerm_storage_blob" "staticweb_error" {
  name                   = "error.html"
  storage_account_name   = azurerm_storage_account.staticweb.name
  storage_container_name = "$web"
  type                   = "Block"
  content_type           = "text/html"
  source_content         = "This is error page."
}

resource "azurerm_storage_container" "code" {
  name                  = "code"
  storage_account_name  = azurerm_storage_account.azfunction.name
  container_access_type = "blob"
}

resource "azurerm_storage_table" "table" {
  name                 = "message"
  storage_account_name = azurerm_storage_account.azfunction.name
}

resource "azurerm_storage_queue" "queue" {
  name                 = "job"
  storage_account_name = azurerm_storage_account.azfunction.name
}

# network for Azure Function (located at southeast asia)
resource "azurerm_virtual_network" "azfunction_network" {
  name                = "projVnet1Prod"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_storage_account.azfunction.location
  resource_group_name = azurerm_resource_group.rg.name

  subnet {
    name           = "projVnet1Prod_subnet1"
    address_prefix = "10.0.1.0/24"
  }
  subnet {
    name           = "projVnet1Prod_subnet2"
    address_prefix = "10.0.0.0/24"
  }
}


#static web virtual network
resource "azurerm_virtual_network" "staticweb_network" {
  name                = "projVnet2Prod"
  address_space       = ["10.1.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  subnet {
    name           = "projVnet2Prod_subnet1"
    address_prefix = "10.1.1.0/24"
  }

  subnet {
    name           = "projVnet2Prod_subnet2"
    address_prefix = "10.1.0.0/24"
  }
}

