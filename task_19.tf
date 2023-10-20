resource "azurerm_network_security_group" "task19" {
  name                = "NetworkSecurityGroup4"
  location            = azurerm_storage_account.staticweb.location
  resource_group_name = azurerm_resource_group.rg.name
  security_rule {
    name                       = "NSG-Rule-1"
    priority                   = 201
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "10.0.0.0/24"
    destination_address_prefix = "10.1.0.0/24"
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

resource "azurerm_subnet_network_security_group_association" "task19_sga" {
  subnet_id                 = azurerm_subnet.staticweb_subnet2.id
  network_security_group_id = azurerm_network_security_group.task19.id
}
