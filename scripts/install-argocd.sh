#!/bin/bash

set -euo pipefail

NAMESPACE="argocd"

# Create namespace if missing
kubectl get ns $NAMESPACE >/dev/null 2>&1 || kubectl create namespace $NAMESPACE

# Add repo
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

# Apply ArgoCD via Helm (upgrade if exists)
helm upgrade --install argocd argo/argo-cd \
    -n $NAMESPACE \
    -f argocd-values.yaml

# Wait for server pod
echo "Waiting for ArgoCD server to become ready..."
kubectl wait \
    -n $NAMESPACE \
    --for=condition=Ready \
    pod -l app.kubernetes.io/name=argocd-server \
    --timeout=300s

echo "Initial admin password:"
kubectl get secret argocd-initial-admin-secret \
    -n $NAMESPACE \
    -o jsonpath="{.data.password}" | base64 --decode
echo
