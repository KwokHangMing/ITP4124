resource "azurerm_application_insights" "task20" {
  name                = "tf-test-appinsights"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  application_type    = "other"
  retention_in_days   = "30"
  tags = {
    key = "ApplicationInsights"
  }
}

