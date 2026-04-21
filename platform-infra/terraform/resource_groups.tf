# One Azure RG per capability stack (BRD §4).
resource "azurerm_resource_group" "stack" {
  for_each = local.resource_groups
  name     = each.value
  location = var.location
  tags     = merge(local.common_tags, { stack = each.key })
}
