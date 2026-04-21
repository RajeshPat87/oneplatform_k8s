locals {
  suffix = "${var.project}-${var.env}"

  # One resource group per capability domain per BRD.
  resource_groups = {
    networking     = "rg-${local.suffix}-networking"
    aks            = "rg-${local.suffix}-aks"
    acr            = "rg-${local.suffix}-acr"
    observability  = "rg-${local.suffix}-observability"
    security_mesh  = "rg-${local.suffix}-security-mesh"
    mlops          = "rg-${local.suffix}-mlops"
    ingress_gitops = "rg-${local.suffix}-ingress-gitops"
    scaling        = "rg-${local.suffix}-scaling"
  }

  common_tags = merge(var.tags, {
    environment = var.env
    managed-by  = "terraform"
  })
}
