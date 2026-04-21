#!/usr/bin/env bash
# One-time Azure + GitHub bootstrap for OnePlatform CI/CD.
#
# Creates (idempotent):
#   - Azure AD app registration + service principal   (sp-oneplatform-cicd)
#   - Federated credentials trusting GitHub OIDC for:
#       * refs/heads/main
#       * pull requests
#       * environment:platform-dev
#   - Role assignments at subscription scope:
#       * Contributor
#       * Role Based Access Control Administrator  (needed for AcrPull assignment in TF)
#   - GitHub repo secrets via `gh` CLI:
#       AZURE_CLIENT_ID, AZURE_TENANT_ID, AZURE_SUBSCRIPTION_ID
#
# Prereqs:
#   - az logged in as subscription Owner
#   - gh logged in with `repo` + `workflow` scopes
#   - GitHub repo already exists (or pass --create-repo)
#
# Usage:
#   ./scripts/azure-bootstrap.sh \
#       --subscription <subId> \
#       --github-owner RajeshPat87 \
#       --github-repo  oneplatform_k8s \
#       [--sp-name sp-oneplatform-cicd] \
#       [--create-repo] [--push]
set -euo pipefail

SP_NAME="sp-oneplatform-cicd"
GH_OWNER=""
GH_REPO=""
SUB_ID=""
CREATE_REPO=false
PUSH_CODE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --subscription)  SUB_ID="$2"; shift 2 ;;
    --github-owner)  GH_OWNER="$2"; shift 2 ;;
    --github-repo)   GH_REPO="$2"; shift 2 ;;
    --sp-name)       SP_NAME="$2"; shift 2 ;;
    --create-repo)   CREATE_REPO=true; shift ;;
    --push)          PUSH_CODE=true; shift ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

: "${SUB_ID:?--subscription required}"
: "${GH_OWNER:?--github-owner required}"
: "${GH_REPO:?--github-repo required}"

echo ">> Using subscription: ${SUB_ID}"
az account set --subscription "${SUB_ID}"
TENANT_ID="$(az account show --query tenantId -o tsv)"

if ${CREATE_REPO}; then
  echo ">> Creating GitHub repo ${GH_OWNER}/${GH_REPO} (private)"
  gh repo view "${GH_OWNER}/${GH_REPO}" >/dev/null 2>&1 \
    || gh repo create "${GH_OWNER}/${GH_REPO}" --private --source=. --remote=origin
fi

echo ">> Ensuring AAD app '${SP_NAME}' exists"
APP_ID="$(az ad app list --display-name "${SP_NAME}" --query '[0].appId' -o tsv)"
if [[ -z "${APP_ID}" ]]; then
  APP_ID="$(az ad app create --display-name "${SP_NAME}" --query appId -o tsv)"
  echo "   created appId=${APP_ID}"
fi
APP_OBJECT_ID="$(az ad app show --id "${APP_ID}" --query id -o tsv)"

echo ">> Ensuring service principal for appId=${APP_ID}"
SP_OBJECT_ID="$(az ad sp list --filter "appId eq '${APP_ID}'" --query '[0].id' -o tsv)"
if [[ -z "${SP_OBJECT_ID}" ]]; then
  SP_OBJECT_ID="$(az ad sp create --id "${APP_ID}" --query id -o tsv)"
  echo "   created spOid=${SP_OBJECT_ID}"
fi

add_federated_credential() {
  local name="$1" subject="$2"
  local existing
  existing="$(az ad app federated-credential list --id "${APP_OBJECT_ID}" --query "[?name=='${name}'] | [0].id" -o tsv)"
  if [[ -n "${existing}" ]]; then
    echo "   federated cred '${name}' exists"
    return
  fi
  cat > /tmp/fic.json <<EOF
{
  "name": "${name}",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "${subject}",
  "audiences": ["api://AzureADTokenExchange"]
}
EOF
  az ad app federated-credential create --id "${APP_OBJECT_ID}" --parameters /tmp/fic.json >/dev/null
  echo "   added federated cred '${name}' -> ${subject}"
}

echo ">> Configuring GitHub OIDC federated credentials"
add_federated_credential "gh-main"    "repo:${GH_OWNER}/${GH_REPO}:ref:refs/heads/main"
add_federated_credential "gh-pr"      "repo:${GH_OWNER}/${GH_REPO}:pull_request"
add_federated_credential "gh-env-dev" "repo:${GH_OWNER}/${GH_REPO}:environment:platform-dev"

assign_role() {
  local role="$1"
  if az role assignment list --assignee "${SP_OBJECT_ID}" --scope "/subscriptions/${SUB_ID}" \
      --query "[?roleDefinitionName=='${role}'] | [0].id" -o tsv | grep -q .; then
    echo "   role '${role}' already assigned"
    return
  fi
  az role assignment create \
    --assignee-object-id "${SP_OBJECT_ID}" \
    --assignee-principal-type ServicePrincipal \
    --role "${role}" \
    --scope "/subscriptions/${SUB_ID}" >/dev/null
  echo "   assigned '${role}'"
}

echo ">> Assigning subscription-scope roles"
assign_role "Contributor"
assign_role "Role Based Access Control Administrator"

echo ">> Setting GitHub repo secrets (${GH_OWNER}/${GH_REPO})"
gh secret set AZURE_CLIENT_ID       -R "${GH_OWNER}/${GH_REPO}" --body "${APP_ID}"
gh secret set AZURE_TENANT_ID       -R "${GH_OWNER}/${GH_REPO}" --body "${TENANT_ID}"
gh secret set AZURE_SUBSCRIPTION_ID -R "${GH_OWNER}/${GH_REPO}" --body "${SUB_ID}"

if ${PUSH_CODE}; then
  echo ">> Pushing code to ${GH_OWNER}/${GH_REPO}"
  if [[ ! -d .git ]]; then
    git init -b main
  fi
  if ! git remote get-url origin >/dev/null 2>&1; then
    git remote add origin "https://github.com/${GH_OWNER}/${GH_REPO}.git"
  fi
  git add -A
  git diff --cached --quiet || git commit -m "feat: scaffold oneplatform monorepo"
  git push -u origin main
fi

cat <<EOF

Bootstrap complete.

  Subscription : ${SUB_ID}
  Tenant       : ${TENANT_ID}
  SP           : ${SP_NAME}
  App (Client) : ${APP_ID}
  SP Object ID : ${SP_OBJECT_ID}

GitHub secrets set on ${GH_OWNER}/${GH_REPO}:
  AZURE_CLIENT_ID, AZURE_TENANT_ID, AZURE_SUBSCRIPTION_ID

Next:
  1) Push the repo to GitHub (re-run with --push, or git push manually).
  2) Run the terraform workflow (creates ACR + AKS + per-stack RGs).
  3) After success, set ACR_NAME and ACR_LOGIN_SERVER GH secrets from the
     terraform outputs:
        gh secret set ACR_NAME        -R ${GH_OWNER}/${GH_REPO} \\
          --body "\$(terraform -chdir=platform-infra/terraform output -raw acr_name)"
        gh secret set ACR_LOGIN_SERVER -R ${GH_OWNER}/${GH_REPO} \\
          --body "\$(terraform -chdir=platform-infra/terraform output -raw acr_login_server)"
  4) (Optional) For Azure DevOps mirror: run scripts/azdo-setup.sh with
     ACR_NAME and ACR_LOGIN_SERVER populated, then convert the ARM service
     connection to Workload Identity Federation using the SAME appId=${APP_ID}.
EOF
