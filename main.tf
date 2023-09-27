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
}

resource "azurerm_subnet" "azfunction_subnet1" {
  name                 = "projVnet1Prod_subnet1"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.azfunction_network.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "azfunction_subnet2" {
  name                 = "projVnet1Prod_subnet2"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.azfunction_network.name
  address_prefixes     = ["10.0.0.0/24"]
}


#static web virtual network
resource "azurerm_virtual_network" "staticweb_network" {
  name                = "projVnet2Prod"
  address_space       = ["10.1.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "staticweb_subnet1" {
  name                 = "projVnet2Prod_subnet1"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.staticweb_network.name
  address_prefixes     = ["10.1.1.0/24"]
}

resource "azurerm_subnet" "staticweb_subnet2" {
  name                 = "projVnet2Prod_subnet2"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.staticweb_network.name
  address_prefixes     = ["10.1.0.0/24"]
}


resource "azurerm_route_table" "projProd_routeTable" {
  name                = "RouteTable"
  location            = azurerm_virtual_network.azfunction_network.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_route" "projVnet1Prod_route" {
  name                = "projVnet1Prod_route1"
  resource_group_name = azurerm_resource_group.rg.name
  route_table_name    = azurerm_route_table.projProd_routeTable.name
  address_prefix      = "10.0.0.0/16"
  next_hop_type       = "VnetLocal"
}

resource "azurerm_route" "projVnet1Prod_route2" {
  name                = "projVnet1Prod_route2"
  resource_group_name = azurerm_resource_group.rg.name
  route_table_name    = azurerm_route_table.projProd_routeTable.name
  address_prefix      = "0.0.0.0/0"
  next_hop_type       = "Internet"
}

resource "azurerm_route_table" "projProd_routeTable2" {
  name                = "RouteTable2"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_route" "projVnet2Prod_route" {
  name                = "projVnet2Prod_route1"
  resource_group_name = azurerm_resource_group.rg.name
  route_table_name    = azurerm_route_table.projProd_routeTable2.name
  address_prefix      = "10.1.0.0/16"
  next_hop_type       = "VnetLocal"
}

resource "azurerm_route" "projVnet2Prod_route2" {
  name                = "projVnet2Prod_route2"
  resource_group_name = azurerm_resource_group.rg.name
  route_table_name    = azurerm_route_table.projProd_routeTable2.name
  address_prefix      = "0.0.0.0/0"
  next_hop_type       = "Internet"
}

resource "azurerm_subnet_route_table_association" "projProd_routeTable_association" {
  subnet_id      = azurerm_subnet.azfunction_subnet1.id
  route_table_id = azurerm_route_table.projProd_routeTable.id
}

resource "azurerm_subnet_route_table_association" "projProd_routeTable_association2" {
  subnet_id      = azurerm_subnet.azfunction_subnet2.id
  route_table_id = azurerm_route_table.projProd_routeTable.id
}

resource "azurerm_subnet_route_table_association" "projProd_routeTable_association3" {
  subnet_id      = azurerm_subnet.staticweb_subnet1.id
  route_table_id = azurerm_route_table.projProd_routeTable2.id
}

resource "azurerm_subnet_route_table_association" "projProd_routeTable_association4" {
  subnet_id      = azurerm_subnet.staticweb_subnet2.id
  route_table_id = azurerm_route_table.projProd_routeTable2.id
}
# NAT Gateway
resource "azurerm_public_ip" "azfunction_publicIP" {
  name                = "azfunction_publicIP"
  location            = azurerm_storage_account.azfunction.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1"]
}

resource "azurerm_public_ip_prefix" "azfunction_publicIPPrefix" {
  name                = "azfunction_publicIPPrefix"
  location            = azurerm_storage_account.azfunction.location
  resource_group_name = azurerm_resource_group.rg.name
  prefix_length       = 30
  zones               = ["1"]
}

resource "azurerm_nat_gateway" "azfunction_natGateway" {
  name                    = "nat-Gateway"
  location                = azurerm_storage_account.azfunction.location
  resource_group_name     = azurerm_resource_group.rg.name
  sku_name                = "Standard"
  idle_timeout_in_minutes = 10
  zones                   = ["1"]
}

resource "azurerm_nat_gateway_public_ip_prefix_association" "azfunction_natGateway_association" {
  nat_gateway_id      = azurerm_nat_gateway.azfunction_natGateway.id
  public_ip_prefix_id = azurerm_public_ip_prefix.azfunction_publicIPPrefix.id
}

resource "azurerm_nat_gateway_public_ip_association" "azfunction_natGateway_association2" {
  nat_gateway_id       = azurerm_nat_gateway.azfunction_natGateway.id
  public_ip_address_id = azurerm_public_ip.azfunction_publicIP.id
}

resource "azurerm_subnet_nat_gateway_association" "azfunction_natGateway_association3" {
  subnet_id      = azurerm_subnet.azfunction_subnet1.id
  nat_gateway_id = azurerm_nat_gateway.azfunction_natGateway.id
}

#Network Peering

resource "azurerm_virtual_network_peering" "azfunction_to_staticweb" {
  name                         = "azfunction_to_staticweb"
  resource_group_name          = azurerm_resource_group.rg.name
  virtual_network_name         = azurerm_virtual_network.azfunction_network.name
  remote_virtual_network_id    = azurerm_virtual_network.staticweb_network.id
  allow_forwarded_traffic      = "true"
  allow_virtual_network_access = "true"
  allow_gateway_transit        = "false"
}

resource "azurerm_virtual_network_peering" "staticweb_to_azfunction" {
  name                         = "staticweb_to_azfunction"
  resource_group_name          = azurerm_resource_group.rg.name
  virtual_network_name         = azurerm_virtual_network.staticweb_network.name
  remote_virtual_network_id    = azurerm_virtual_network.azfunction_network.id
  allow_forwarded_traffic      = "true"
  allow_virtual_network_access = "true"
  allow_gateway_transit        = "false"
}

# Security Rules

resource "azurerm_network_security_group" "projVnet1Prod_security_group" {
  name                = "NetworkSecurityGroup"
  location            = azurerm_storage_account.azfunction.location
  resource_group_name = azurerm_resource_group.rg.name
  security_rule {
    name                       = "NSG-Rule-1"
    priority                   = 201
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "10.0.1.0/24"
  }

  security_rule {
    name                       = "NSG-Rule-2"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "projVnet1Prod_security_group_association" {
  subnet_id                 = azurerm_subnet.azfunction_subnet1.id
  network_security_group_id = azurerm_network_security_group.projVnet1Prod_security_group.id
}

#Task 17

# resource "azurerm_network_security_group" "projVnet2Prod_security_group" {
#   name                = "projVnet2Prod_security_group"
#   location            = azurerm_storage_account.staticweb.location
#   resource_group_name = azurerm_resource_group.rg.name
#   security_rule {
#     name                         = "projVnet2Prod_security_rule1"
#     priority                     = 201
#     direction                    = "Inbound"
#     access                       = "Allow"
#     protocol                     = "Tcp"
#     source_port_range            = "*"
#     destination_port_range       = "80"
#     source_address_prefix        = "10.1.0.0/24"
#     destination_address_prefixes = azurerm_subnet.staticweb_subnet1.address_prefixes
#   }

#   security_rule {
#     name                       = "projVnet2Prod_security_rule2"
#     priority                   = 100
#     direction                  = "Outbound"
#     access                     = "Allow"
#     protocol                   = "Tcp"
#     source_port_range          = "*"
#     destination_port_range     = "*"
#     source_address_prefix      = "*"
#     destination_address_prefix = "*"
#   }
# }
# resource "azurerm_subnet_network_security_group_association" "projVnet2Prod_security_group_association" {
#   subnet_id                 = azurerm_subnet.staticweb_subnet1.id
#   network_security_group_id = azurerm_network_security_group.projVnet2Prod_security_group.id
# }

resource "azurerm_network_security_group" "projVnet2Prod_security_group" {
  name                = "projVnet2Prod_security_group"
  location            = azurerm_storage_account.staticweb.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_network_security_rule" "projVnet2Prod_security_rule1" {
  name                         = "projVnet2Prod_security_rule1"
  priority                     = 201
  direction                    = "Inbound"
  access                       = "Allow"
  protocol                     = "Tcp"
  source_port_range            = "*"
  destination_port_range       = "80"
  source_address_prefix        = "10.1.0.0/24"
  destination_address_prefixes = azurerm_subnet.staticweb_subnet1.address_prefixes
  resource_group_name          = azurerm_resource_group.rg.name
  network_security_group_name  = azurerm_network_security_group.projVnet2Prod_security_group.name
}

resource "azurerm_network_security_rule" "projVnet2Prod_security_rule2" {
  name                        = "projVnet2Prod_security_rule2"
  priority                    = 100
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.projVnet2Prod_security_group.name
}

resource "azurerm_subnet_network_security_group_association" "projVnet2Prod_security_group_association" {
  subnet_id                 = azurerm_subnet.staticweb_subnet1.id
  network_security_group_id = azurerm_network_security_group.projVnet2Prod_security_group.id
}
