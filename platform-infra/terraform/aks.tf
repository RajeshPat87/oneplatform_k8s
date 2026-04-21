resource "azurerm_log_analytics_workspace" "obs" {
  name                = "law-${local.suffix}"
  resource_group_name = azurerm_resource_group.stack["observability"].name
  location            = var.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = azurerm_resource_group.stack["observability"].tags
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-${local.suffix}"
  resource_group_name = azurerm_resource_group.stack["aks"].name
  location            = var.location
  dns_prefix          = "aks-${local.suffix}"
  kubernetes_version  = var.aks_k8s_version
  # Dedicated node RG so cluster-managed resources stay inside the AKS RG boundary.
  node_resource_group = "rg-${local.suffix}-aks-nodes"

  default_node_pool {
    name           = "system"
    node_count     = var.aks_node_count
    vm_size        = var.aks_vm_size
    vnet_subnet_id = azurerm_subnet.aks.id
    type           = "VirtualMachineScaleSets"
    os_disk_type   = "Managed"
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_policy      = "cilium"
    network_dataplane   = "cilium"
  }

  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.obs.id
  }

  azure_policy_enabled = true
  role_based_access_control_enabled = true

  tags = azurerm_resource_group.stack["aks"].tags
}

# User pool for workload pods
resource "azurerm_kubernetes_cluster_node_pool" "apps" {
  name                  = "apps"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  vm_size               = var.aks_vm_size
  node_count            = var.aks_node_count
  vnet_subnet_id        = azurerm_subnet.aks.id
  mode                  = "User"
  node_labels           = { workload = "apps" }
}

# Allow AKS kubelet identity to pull from ACR
resource "azurerm_role_assignment" "aks_acr_pull" {
  principal_id                     = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.acr.id
  skip_service_principal_aad_check = true
}
