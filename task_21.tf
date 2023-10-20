# resource "azurerm_service_plan" "windows" {
#   name                = "windows-service-plan"
#   location            = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name
#   os_type             = "Windows"
#   sku_name            = "Y1"
#   tags = {
#     key = "AppServicePlan"
#   }
# }

# Solution here

resource "azurerm_app_service_plan" "windows" {
  name                = "AppServicePlan"
  location            = azurerm_storage_account.azfunction.location
  resource_group_name = azurerm_resource_group.rg.name
  kind                = "Windows"


  sku {
    tier = "Dynamic"
    size = "Y1"
  }
  tags = {
    key = "AppServicePlan"
  }
}


#│ The `azurerm_app_service_plan` resource has been superseded by the `azurerm_service_plan` resource. Whilst this resource will continue to be available in the 2.x and 3.x releases
# it is feature-frozen for compatibility purposes, will no longer receive any updates and will be removed in a future major release of the Azure Provider.

# resource "azurerm_windows_function_app" "task21" {
#   name                = "task21-function"
#   location            = azurerm_storage_account.azfunction.location
#   resource_group_name = azurerm_resource_group.rg.name
#   service_plan_id     = azurerm_app_service_plan.windows.id

#   storage_account_name        = azurerm_storage_account.azfunction.name
#   storage_account_access_key  = azurerm_storage_account.azfunction.primary_access_key
#   functions_extension_version = "~4"

#   site_config {
#     application_stack {
#       node_version = "~16"

#     }
#     always_on = "false"

#   }
#   tags = {
#     key = "FunctionApp"
#   }
# }

resource "azurerm_function_app" "example" {
  name                = "task21-function"
  location            = azurerm_storage_account.azfunction.location
  resource_group_name = azurerm_resource_group.rg.name
  app_service_plan_id = azurerm_app_service_plan.windows.id

  storage_account_name       = azurerm_storage_account.azfunction.name
  storage_account_access_key = azurerm_storage_account.azfunction.primary_access_key
  version                    = "~4"

  site_config {
    always_on = "false"
  }
  app_settings = {
    "FUNCTIONS_EXTENSION_VERSION" = "~4"
    "FUNCTIONS_WORKER_RUNTIME" = "node"
    "WEBSITE_NODE_DEFAULT_VERSION" = "~16"
  }
  tags = {
    # AppServicePlan = azurerm_app_service_plan.windows.name
    # FunctionApp = azurerm_function_app.example.name
    key = "FunctionApp"
  }
}
