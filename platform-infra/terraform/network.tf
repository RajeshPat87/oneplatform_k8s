resource "azurerm_virtual_network" "platform" {
  name                = "vnet-${local.suffix}"
  resource_group_name = azurerm_resource_group.stack["networking"].name
  location            = var.location
  address_space       = [var.vnet_cidr]
  tags                = azurerm_resource_group.stack["networking"].tags
}

resource "azurerm_subnet" "aks" {
  name                 = "snet-aks"
  resource_group_name  = azurerm_resource_group.stack["networking"].name
  virtual_network_name = azurerm_virtual_network.platform.name
  address_prefixes     = [var.aks_subnet_cidr]
}

resource "azurerm_subnet" "private_endpoints" {
  name                 = "snet-pe"
  resource_group_name  = azurerm_resource_group.stack["networking"].name
  virtual_network_name = azurerm_virtual_network.platform.name
  address_prefixes     = [var.pe_subnet_cidr]
  private_endpoint_network_policies = "Disabled"
}
