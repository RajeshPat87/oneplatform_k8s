#!/usr/bin/env bash
# One-time bootstrap for Azure DevOps to mirror the GitHub Actions pipelines.
# Creates: service connections, variable groups, environment, and pipelines.
#
# Required env:
#   ADO_ORG_URL          e.g. https://dev.azure.com/RajeshPatibandla1987
#   ADO_PROJECT          e.g. oneplatform
#   ADO_REPO_NAME        e.g. oneplatform_k8s (must be imported into Azure Repos already)
#   AZURE_SUBSCRIPTION_ID
#   AZURE_SUBSCRIPTION_NAME  (exact display name)
#   AZURE_TENANT_ID
#   ACR_NAME                 (the ACR created by Terraform)
#   ACR_LOGIN_SERVER         (e.g. acroneplatformdevxxxxxx.azurecr.io)
#
# Optional (for terraform backend variable group):
#   TF_BACKEND_RESOURCE_GROUP_NAME  (default rg-terraform-state)
#   TF_BACKEND_STORAGE_ACCOUNT_NAME (default tfstaterajesh15282)
#   TF_BACKEND_CONTAINER_NAME       (default tfstate)
#   TF_BACKEND_LOCATION             (default eastus)
set -euo pipefail

: "${ADO_ORG_URL:?}"
: "${ADO_PROJECT:?}"
: "${ADO_REPO_NAME:?}"
: "${AZURE_SUBSCRIPTION_ID:?}"
: "${AZURE_SUBSCRIPTION_NAME:?}"
: "${AZURE_TENANT_ID:?}"
: "${ACR_NAME:?}"
: "${ACR_LOGIN_SERVER:?}"

TF_BACKEND_RESOURCE_GROUP_NAME="${TF_BACKEND_RESOURCE_GROUP_NAME:-rg-terraform-state}"
TF_BACKEND_STORAGE_ACCOUNT_NAME="${TF_BACKEND_STORAGE_ACCOUNT_NAME:-tfstaterajesh15282}"
TF_BACKEND_CONTAINER_NAME="${TF_BACKEND_CONTAINER_NAME:-tfstate}"
TF_BACKEND_LOCATION="${TF_BACKEND_LOCATION:-eastus}"

az devops configure --defaults "organization=${ADO_ORG_URL}" "project=${ADO_PROJECT}"

echo ">> ensuring project exists"
az devops project show --project "${ADO_PROJECT}" >/dev/null 2>&1 \
  || az devops project create --name "${ADO_PROJECT}" --visibility private >/dev/null

echo ">> ensuring Azure Resource Manager service connection 'azure-oneplatform' (workload identity federation)"
if ! az devops service-endpoint list --query "[?name=='azure-oneplatform'] | [0].id" -o tsv | grep -q .; then
  az devops service-endpoint azurerm create \
    --name azure-oneplatform \
    --azure-rm-service-principal-id "" \
    --azure-rm-subscription-id   "${AZURE_SUBSCRIPTION_ID}" \
    --azure-rm-subscription-name "${AZURE_SUBSCRIPTION_NAME}" \
    --azure-rm-tenant-id         "${AZURE_TENANT_ID}" >/dev/null
  echo "   NOTE: convert to Workload Identity Federation in the ADO UI for passwordless auth."
fi

echo ">> ensuring Docker Registry (ACR) service connection 'acr-oneplatform'"
if ! az devops service-endpoint list --query "[?name=='acr-oneplatform'] | [0].id" -o tsv | grep -q .; then
  cat > /tmp/acr-sc.json <<EOF
{
  "name": "acr-oneplatform",
  "type": "dockerregistry",
  "url": "https://${ACR_LOGIN_SERVER}",
  "authorization": { "scheme": "ServicePrincipal", "parameters": { "registrytype": "ACR", "scope": "${AZURE_SUBSCRIPTION_ID}" } },
  "data": { "registryId": "/subscriptions/${AZURE_SUBSCRIPTION_ID}/resourceGroups/rg-oneplatform-dev-acr/providers/Microsoft.ContainerRegistry/registries/${ACR_NAME}", "registrytype": "ACR" }
}
EOF
  az devops service-endpoint create --service-endpoint-configuration /tmp/acr-sc.json >/dev/null
fi

echo ">> creating variable group 'oneplatform-common'"
VG_ID=$(az pipelines variable-group list --query "[?name=='oneplatform-common'] | [0].id" -o tsv || true)
if [[ -z "${VG_ID}" ]]; then
  VG_ID=$(az pipelines variable-group create \
    --name oneplatform-common \
    --variables "ACR_NAME=${ACR_NAME}" "ACR_LOGIN_SERVER=${ACR_LOGIN_SERVER}" "AZURE_SUBSCRIPTION_ID=${AZURE_SUBSCRIPTION_ID}" \
    --query id -o tsv)
  echo "   created variable group id=${VG_ID}"
fi

echo ">> creating variable group 'oneplatform-tf-backend'"
if ! az pipelines variable-group list --query "[?name=='oneplatform-tf-backend'] | [0].id" -o tsv | grep -q .; then
  az pipelines variable-group create \
    --name oneplatform-tf-backend \
    --variables "TF_BACKEND_RESOURCE_GROUP_NAME=${TF_BACKEND_RESOURCE_GROUP_NAME}" \
                "TF_BACKEND_STORAGE_ACCOUNT_NAME=${TF_BACKEND_STORAGE_ACCOUNT_NAME}" \
                "TF_BACKEND_CONTAINER_NAME=${TF_BACKEND_CONTAINER_NAME}" \
                "TF_BACKEND_LOCATION=${TF_BACKEND_LOCATION}" >/dev/null
fi

echo ">> ensuring ADO environment 'platform-dev' (for approval gates)"
EXISTING_ENV=$(az devops invoke --area distributedtask --resource environments \
  --route-parameters project="${ADO_PROJECT}" --api-version 7.1-preview.1 2>/dev/null \
  | jq -r '.value[]? | select(.name=="platform-dev") | .id' || true)
if [[ -z "${EXISTING_ENV}" ]]; then
  az devops invoke --area distributedtask --resource environments \
    --http-method POST --in-file /dev/stdin --api-version 7.1-preview.1 \
    --route-parameters project="${ADO_PROJECT}" >/dev/null <<< '{"name":"platform-dev","description":"OnePlatform dev environment"}' \
    || true
fi

PIPELINES=(
  "oneplatform-ci-backend|.azure-pipelines/ci-backend.yml"
  "oneplatform-ci-frontend|.azure-pipelines/ci-frontend.yml"
  "oneplatform-ci-ai-service|.azure-pipelines/ci-ai-service.yml"
  "oneplatform-terraform|.azure-pipelines/terraform.yml"
  "oneplatform-helm-lint|.azure-pipelines/helm-lint.yml"
  "oneplatform-opa-conftest|.azure-pipelines/opa-conftest.yml"
)

echo ">> creating pipelines"
for entry in "${PIPELINES[@]}"; do
  name="${entry%%|*}"
  yaml="${entry##*|}"
  if az pipelines show --name "${name}" >/dev/null 2>&1; then
    echo "   - ${name} exists"
    continue
  fi
  az pipelines create \
    --name "${name}" \
    --repository "${ADO_REPO_NAME}" \
    --repository-type tfsgit \
    --branch main \
    --yaml-path "${yaml}" \
    --skip-first-run true >/dev/null
  echo "   - ${name} created"
done

echo ""
echo "Azure DevOps setup complete."
echo "Next:"
echo "  1. Open ADO > Project Settings > Service connections > 'azure-oneplatform' and convert to Workload Identity Federation."
echo "  2. Link the ADO pipelines to access 'oneplatform-common' and 'oneplatform-tf-backend' variable groups (first run will prompt)."
echo "  3. Ensure ${ADO_REPO_NAME} has 'Allow scripts to access OAuth token' enabled for the gitops-bump step."
