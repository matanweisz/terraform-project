#!/bin/bash

set -euo pipefail

NAMESPACE="kube-system"

# Load environment variables
if [ -f .env ]; then
    echo "Loading environment variables from .env"
    set -o allexport
    source .env
    set +o allexport
else
    echo "The .env file not found in the current directory!"
    exit 1
fi

echo "Checking namespace..."
kubectl get ns $NAMESPACE >/dev/null 2>&1 || kubectl create namespace $NAMESPACE

echo "Creating service account with IRSA annotations..."
kubectl get serviceaccount ${ALB_CONTROLLER_SA} -n $NAMESPACE >/dev/null 2>&1 || \
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ${ALB_CONTROLLER_SA}
  namespace: ${NAMESPACE}
  annotations:
    eks.amazonaws.com/role-arn: ${ALB_CONTROLLER_ROLE_ARN}
EOF

echo "Adding EKS charts repo..."
helm repo add eks https://aws.github.io/eks-charts
helm repo update

echo "Installing AWS Load Balancer Controller..."
helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
    -n $NAMESPACE \
    --set clusterName="${CLUSTER_NAME}" \
    --set serviceAccount.name="${ALB_CONTROLLER_SA}" \
    --set serviceAccount.create=false \
    --set region="${AWS_REGION}" \
    --set vpcId="${VPC_ID}"

echo "Waiting for AWS Load Balancer Controller deployment to be ready..."
kubectl rollout status deployment/aws-load-balancer-controller \
    -n $NAMESPACE \
    --timeout=180s

echo "AWS Load Balancer Controller installation complete!"
