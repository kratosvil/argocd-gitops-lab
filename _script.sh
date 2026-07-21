#!/usr/bin/env bash
set -euo pipefail

# Módulo 1 (SAGA): carga el PAT de saga-gitops-manifests como:
#   1. Credencial de repo para ArgoCD (namespace argocd, in-cluster)
#   2. Secret de GitHub Actions en argocd-gitops-aws (para el CI del Módulo 1)
# El token nunca se imprime ni queda en ningun archivo de este repo.

read -rsp "Pegá el PAT de grano fino (Contents: Read & Write, repo saga-gitops-manifests): " TOKEN
echo ""

if [ -z "$TOKEN" ]; then
  echo "Token vacío, cancelado."
  exit 1
fi

echo "=== 1/2: credencial de ArgoCD ==="
kubectl create secret generic saga-gitops-manifests-creds \
  --namespace argocd \
  --from-literal=type=git \
  --from-literal=url=https://github.com/kratosvil/saga-gitops-manifests.git \
  --from-literal=username=x-access-token \
  --from-literal=password="$TOKEN" \
  --dry-run=client -o yaml \
  | kubectl label --local -f - argocd.argoproj.io/secret-type=repository -o yaml \
  | kubectl apply -f -

echo "=== 2/2: secret de GitHub Actions ==="
echo "$TOKEN" | gh secret set SAGA_MANIFESTS_TOKEN --repo kratosvil/argocd-gitops-aws

unset TOKEN

echo ""
echo "Listo. Forzando refresh de las Applications dev/prod..."
kubectl patch application kratosvil-replica-app-dev -n argocd --type merge \
  -p '{"metadata":{"annotations":{"argocd.argoproj.io/refresh":"hard"}}}'
kubectl patch application kratosvil-replica-app-prod -n argocd --type merge \
  -p '{"metadata":{"annotations":{"argocd.argoproj.io/refresh":"hard"}}}'
sleep 10
kubectl get application -n argocd kratosvil-replica-app-dev kratosvil-replica-app-prod
