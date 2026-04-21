#!/usr/bin/env bash
# One-time bootstrap: ensure Azure resources for the Terraform remote backend
# (RG + Storage Account + blob container) exist with secure defaults.
#
# Override via env:
#   TF_BACKEND_RESOURCE_GROUP_NAME  (default rg-terraform-state)
#   TF_BACKEND_STORAGE_ACCOUNT_NAME (default tfstaterajesh15282)
#   TF_BACKEND_CONTAINER_NAME       (default tfstate)
#   TF_BACKEND_LOCATION             (default eastus)
#   TF_BACKEND_CREATE_IF_MISSING    (default true)
set -euo pipefail

backend_resource_group="${TF_BACKEND_RESOURCE_GROUP_NAME:-rg-terraform-state}"
backend_storage_account="${TF_BACKEND_STORAGE_ACCOUNT_NAME:-tfstaterajesh15282}"
backend_container="${TF_BACKEND_CONTAINER_NAME:-tfstate}"
backend_location="${TF_BACKEND_LOCATION:-eastus}"
create_if_missing="${TF_BACKEND_CREATE_IF_MISSING:-true}"

require_resolved_value() {
  local name="$1"
  local value="$2"
  if [[ -z "${value}" || "${value}" =~ ^\$\(.+\)$ ]]; then
    echo "Required variable '${name}' is missing or unresolved." >&2
    exit 1
  fi
}

require_resolved_value "TF_BACKEND_RESOURCE_GROUP_NAME" "${backend_resource_group}"
require_resolved_value "TF_BACKEND_STORAGE_ACCOUNT_NAME" "${backend_storage_account}"
require_resolved_value "TF_BACKEND_CONTAINER_NAME" "${backend_container}"
require_resolved_value "TF_BACKEND_LOCATION" "${backend_location}"
require_resolved_value "TF_BACKEND_CREATE_IF_MISSING" "${create_if_missing}"

if [[ "${create_if_missing}" != "true" && "${create_if_missing}" != "false" ]]; then
  echo "TF_BACKEND_CREATE_IF_MISSING must be 'true' or 'false'." >&2
  exit 1
fi

if [[ "$(az group exists --name "${backend_resource_group}")" != "true" ]]; then
  if [[ "${create_if_missing}" != "true" ]]; then
    echo "Terraform backend resource group '${backend_resource_group}' does not exist." >&2
    exit 1
  fi
  az group create \
    --name "${backend_resource_group}" \
    --location "${backend_location}" \
    --tags ManagedBy=oneplatform Purpose=TerraformState >/dev/null
fi

if ! az storage account show --name "${backend_storage_account}" --resource-group "${backend_resource_group}" >/dev/null 2>&1; then
  if [[ "${create_if_missing}" != "true" ]]; then
    echo "Terraform backend storage account '${backend_storage_account}' does not exist in resource group '${backend_resource_group}'." >&2
    exit 1
  fi
  if [[ "$(az storage account check-name --name "${backend_storage_account}" --query nameAvailable -o tsv)" != "true" ]]; then
    echo "Storage account name '${backend_storage_account}' is unavailable. Update TF_BACKEND_STORAGE_ACCOUNT_NAME to a unique value." >&2
    exit 1
  fi

  az storage account create \
    --name "${backend_storage_account}" \
    --resource-group "${backend_resource_group}" \
    --location "${backend_location}" \
    --sku Standard_LRS \
    --kind StorageV2 \
    --min-tls-version TLS1_2 \
    --allow-blob-public-access false >/dev/null
else
  az storage account update \
    --name "${backend_storage_account}" \
    --resource-group "${backend_resource_group}" \
    --allow-blob-public-access false \
    --min-tls-version TLS1_2 >/dev/null
fi

az storage account blob-service-properties update \
  --account-name "${backend_storage_account}" \
  --resource-group "${backend_resource_group}" \
  --enable-versioning true \
  --enable-delete-retention true \
  --delete-retention-days 7 \
  --enable-container-delete-retention true \
  --container-delete-retention-days 7 >/dev/null

container_exists="$(az storage container-rm exists \
  --storage-account "${backend_storage_account}" \
  --resource-group "${backend_resource_group}" \
  --name "${backend_container}" \
  --query exists -o tsv)"

if [[ "${container_exists}" != "true" ]]; then
  if [[ "${create_if_missing}" != "true" ]]; then
    echo "Terraform backend container '${backend_container}' does not exist in storage account '${backend_storage_account}'." >&2
    exit 1
  fi
  az storage container-rm create \
    --storage-account "${backend_storage_account}" \
    --resource-group "${backend_resource_group}" \
    --name "${backend_container}" >/dev/null
fi

echo "Terraform backend ready:"
echo "  resource group : ${backend_resource_group}"
echo "  storage account: ${backend_storage_account}"
echo "  container      : ${backend_container}"
