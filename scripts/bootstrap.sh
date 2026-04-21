#!/usr/bin/env bash
# Bootstrap OnePlatform: after `terraform apply`, install ArgoCD + register the
# app-of-apps so everything else syncs automatically.
set -euo pipefail

ENV="${1:-dev}"
AKS_RG="$(terraform -chdir=platform-infra/terraform output -raw aks_resource_group)"
AKS_NAME="$(terraform -chdir=platform-infra/terraform output -raw aks_name)"

echo ">> fetching kubeconfig for ${AKS_NAME}"
az aks get-credentials --resource-group "${AKS_RG}" --name "${AKS_NAME}" --overwrite-existing

echo ">> installing ArgoCD"
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
helm upgrade --install argocd argo/argo-cd \
  --namespace argocd --create-namespace \
  --set server.service.type=ClusterIP

kubectl -n argocd rollout status deploy/argocd-server --timeout=300s

echo ">> registering AppProject"
kubectl apply -f argocd-apps/project.yaml

echo ">> registering app-of-apps for env=${ENV}"
kubectl apply -f "argocd-apps/${ENV}/app-of-apps.yaml"

echo ">> done. Check 'kubectl -n argocd get applications'"
