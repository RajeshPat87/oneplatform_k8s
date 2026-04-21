data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "vault" {
  name                       = "kv-${local.suffix}-${random_string.acr_suffix.result}"
  resource_group_name        = azurerm_resource_group.stack["security_mesh"].name
  location                   = var.location
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  purge_protection_enabled   = false
  rbac_authorization_enabled = true
  tags                       = azurerm_resource_group.stack["security_mesh"].tags
}
