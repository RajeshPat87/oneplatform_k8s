resource "random_string" "acr_suffix" {
  length  = 6
  upper   = false
  special = false
  numeric = true
}

resource "azurerm_container_registry" "acr" {
  name                          = "acr${var.project}${var.env}${random_string.acr_suffix.result}"
  resource_group_name           = azurerm_resource_group.stack["acr"].name
  location                      = var.location
  sku                           = "Premium"
  admin_enabled                 = false
  public_network_access_enabled = false
  tags                          = azurerm_resource_group.stack["acr"].tags
}
