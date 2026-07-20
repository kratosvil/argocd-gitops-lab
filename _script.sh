#!/usr/bin/env bash
set -euo pipefail

# Prerrequisito SV-AOP-012 (SAGA): redeploy de EKS + ArgoCD (base SV-ARG-011)
# Aplica los 6 stacks en orden de dependencia. Cada terraform apply pide
# confirmacion interactiva (yes) despues de mostrar el plan - revisar antes de aprobar.

cd "$(dirname "$0")/terraform"

for stack in vpc eks ecr iam argocd alb-controller; do
  echo "=== Stack: $stack ==="
  (cd "$stack" && terraform init && terraform apply)
done

echo ""
echo "=== Verificacion ==="
kubectl get nodes
kubectl get pods -n argocd
