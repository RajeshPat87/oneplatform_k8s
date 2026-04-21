# Storage account in the MLOps RG for MLflow artifacts / model binaries.
resource "azurerm_storage_account" "mlops" {
  name                     = "stmlops${var.env}${random_string.acr_suffix.result}"
  resource_group_name      = azurerm_resource_group.stack["mlops"].name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
  tags                     = azurerm_resource_group.stack["mlops"].tags
}

resource "azurerm_storage_container" "mlflow" {
  name                  = "mlflow-artifacts"
  storage_account_name  = azurerm_storage_account.mlops.name
  container_access_type = "private"
}
