# ArgoCD Cross-Cluster Deployment Guide

This document explains how ArgoCD in the `internal-cluster` manages applications in the `prod-cluster`.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│  Foundation Layer (VPC: 10.0.0.0/16)                            │
│                                                                  │
│  ┌────────────────────────────┐   ┌────────────────────────┐  │
│  │  Internal Cluster          │   │  Prod Cluster          │  │
│  │  (internal-cluster)        │   │  (prod-cluster)        │  │
│  │                             │   │                        │  │
│  │  ┌──────────────────┐      │   │  ┌──────────────┐     │  │
│  │  │  ArgoCD          │──────┼───┼─►│  Weather App │     │  │
│  │  │  (GitOps)        │      │   │  │              │     │  │
│  │  └──────────────────┘      │   │  └──────────────┘     │  │
│  │                             │   │                        │  │
│  │  - Jenkins                  │   │  - ALB Ingress        │  │
│  │  - Grafana                  │   │  - Application Pods   │  │
│  │  - Prometheus               │   │                        │  │
│  │  - n8n                      │   │                        │  │
│  └────────────────────────────┘   └────────────────────────┘  │
│           │                                  │                  │
│           └──────── Same VPC ────────────────┘                 │
└─────────────────────────────────────────────────────────────────┘
```

## How It Works

### 1. Network Connectivity

**Security Group Rules** (configured in `modules/cluster-access`):

```hcl
# Allow internal cluster to communicate with prod cluster API
ingress {
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  source      = internal-cluster-security-group
}

# Allow internal cluster to communicate with prod cluster nodes
ingress {
  from_port   = 0
  to_port     = 65535
  protocol    = "tcp"
  source      = internal-cluster-security-group
}
```

**Result**: ArgoCD pods in internal-cluster can reach prod-cluster API server and application pods.

### 2. Authentication

ArgoCD authenticates to the prod-cluster using **AWS IAM authentication**:

**Step 1**: ArgoCD uses its IRSA role from the foundation layer
```bash
# ArgoCD pod has this annotation
eks.amazonaws.com/role-arn: arn:aws:iam::ACCOUNT:role/foundation-terraform-project-argocd
```

**Step 2**: ArgoCD's IAM role has EKS permissions
```json
{
  "Effect": "Allow",
  "Action": [
    "eks:DescribeCluster",
    "eks:ListClusters"
  ],
  "Resource": "*"
}
```

**Step 3**: ArgoCD generates authentication token for prod-cluster
```bash
# ArgoCD internally executes (simplified)
aws eks get-token --cluster-name prod-cluster
```

**Step 4**: Prod-cluster's `aws-auth` ConfigMap is updated to allow ArgoCD role
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - rolearn: arn:aws:iam::ACCOUNT:role/foundation-terraform-project-argocd
      username: argocd
      groups:
        - system:masters  # Or custom RBAC group
```

### 3. Authorization

**Kubernetes RBAC** in prod-cluster defines what ArgoCD can do:

```yaml
# ClusterRole for ArgoCD
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: argocd-manager-role
rules:
  - apiGroups: ["*"]
    resources: ["*"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]

---
# ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: argocd-manager-binding
subjects:
  - kind: User
    name: argocd
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: argocd-manager-role
  apiGroup: rbac.authorization.k8s.io
```

**Production Recommendation**: Instead of `system:masters`, create a custom Role with least-privilege permissions for deploying only the weather-app namespace.

## Security Model

### Production Environment Hardening

The prod-cluster is intentionally minimal and secure:

| Feature | Internal Cluster | Prod Cluster | Reason |
|---------|------------------|--------------|---------|
| **Jenkins** | ✅ Deployed | ❌ Not deployed | CI happens in internal cluster |
| **ArgoCD** | ✅ Deployed | ❌ Not deployed | GitOps managed from internal cluster |
| **Grafana** | ✅ Deployed | ❌ Not deployed | Monitoring from internal cluster |
| **External Secrets** | ✅ Deployed | ❌ Not deployed | Reduces attack surface |
| **ALB Ingress** | ✅ Deployed | ✅ Deployed | Public access to app |
| **Application Pods** | ❌ Not deployed | ✅ Deployed | Production workloads only |

### Network Isolation

```
Internet
   │
   ├──► ALB (Public) ──► Prod Cluster ──► Weather App
   │
   └──► ALB (Internal) ──► Internal Cluster ──► Jenkins/ArgoCD/Grafana
```

**Access patterns**:
- **Public users** → ALB → Prod cluster (weather app)
- **Developers** → Internal ALB → Internal cluster (Jenkins/ArgoCD)
- **ArgoCD** → Prod cluster API (deployment only)
- **Prometheus (internal)** → Prod cluster nodes (metrics scraping)

### IAM Security

**Principle of Least Privilege**:

| Component | IAM Permissions | Why |
|-----------|----------------|-----|
| **ArgoCD** | `eks:DescribeCluster`, `secretsmanager:GetSecretValue` | Only what's needed for deployments |
| **ALB Controller (prod)** | `elasticloadbalancing:*`, `ec2:*` (scoped) | Manage ALBs only |
| **Jenkins (internal)** | `ecr:PutImage` | Push images only |
| **App pods (prod)** | None | Stateless app, no AWS access needed |

### Secrets Management

**Production approach** (no External Secrets Operator):

1. **Build-time secrets**: Baked into container image (not recommended for sensitive data)
2. **ArgoCD secrets**: Stored in ArgoCD's secret management
3. **K8s Secrets**: Managed via ArgoCD from Git (encrypted at rest in etcd)

**Future enhancement**: Use AWS Secrets Manager with External Secrets only if needed, but prefer to keep prod minimal.

## ArgoCD Configuration

### Adding Prod Cluster to ArgoCD

**Via ArgoCD UI**:
1. Navigate to Settings → Clusters
2. Click "Connect a cluster using AWS"
3. Enter cluster name: `prod-cluster`
4. ArgoCD auto-discovers using IAM role

**Via CLI**:
```bash
# From internal cluster
argocd cluster add prod-cluster --name prod-cluster

# Verify
argocd cluster list
```

**Via Declarative Config** (recommended):
```yaml
# cluster-secret.yaml (applied to internal cluster)
apiVersion: v1
kind: Secret
metadata:
  name: prod-cluster-secret
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: cluster
type: Opaque
stringData:
  name: prod-cluster
  server: https://PROD_CLUSTER_ENDPOINT
  config: |
    {
      "awsAuthConfig": {
        "clusterName": "prod-cluster",
        "roleARN": ""
      },
      "tlsClientConfig": {
        "insecure": false
      }
    }
```

### Deploying Weather App

**Application manifest** (applied to internal cluster):
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: weather-app-prod
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/YOUR_ORG/weather-app-gitops
    targetRevision: main
    path: prod
  destination:
    server: https://PROD_CLUSTER_ENDPOINT  # prod-cluster
    namespace: weather-app
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

## Monitoring Cross-Cluster

### Prometheus Scraping

**Prometheus in internal-cluster scrapes prod-cluster**:

```yaml
# prometheus-config.yaml
scrape_configs:
  - job_name: 'prod-cluster-nodes'
    kubernetes_sd_configs:
      - role: node
        api_server: https://PROD_CLUSTER_ENDPOINT
        authorization:
          credentials_file: /var/run/secrets/kubernetes.io/serviceaccount/token
    relabel_configs:
      - source_labels: [__address__]
        target_label: cluster
        replacement: prod-cluster
```

**Requires**:
- Prometheus IAM role with `eks:DescribeCluster`
- Security group rule allowing internal cluster → prod cluster nodes (already configured)

### Grafana Dashboards

Grafana in internal-cluster visualizes metrics from:
- **Prometheus (internal)** → Internal cluster metrics
- **Prometheus (internal)** → Prod cluster metrics (via cross-cluster scraping)

**No Prometheus in prod cluster** = simpler, more secure.

## Troubleshooting

### ArgoCD Can't Connect to Prod Cluster

**Check 1: Security Groups**
```bash
# Verify security group rules exist
aws ec2 describe-security-group-rules \
  --filters "Name=group-id,Values=PROD_CLUSTER_SG_ID" \
  --query 'SecurityGroupRules[?FromPort==`443`]'
```

**Check 2: IAM Permissions**
```bash
# Verify ArgoCD role has EKS permissions
aws iam get-policy-version \
  --policy-arn arn:aws:iam::ACCOUNT:policy/foundation-terraform-project-argocd-eks-access-policy \
  --version-id v1
```

**Check 3: aws-auth ConfigMap**
```bash
# Check if ArgoCD role is in aws-auth
kubectl get configmap aws-auth -n kube-system -o yaml
```

### Deployment Stuck in Progressing

**Check ArgoCD logs**:
```bash
kubectl logs -n argocd deployment/argocd-application-controller -f
```

**Common issues**:
- Image pull errors (check ECR permissions)
- Resource limits (check node capacity)
- ALB ingress not ready (check ALB controller)

### Network Connectivity Issues

**Test from internal cluster to prod cluster API**:
```bash
# Run a test pod in internal cluster
kubectl run test --rm -it --image=curlimages/curl -- sh

# Inside pod
curl -k https://PROD_CLUSTER_ENDPOINT/livez
```

**Expected**: HTTP 200 OK (if unauthenticated, may return 401, but proves connectivity)

## Best Practices

### 1. GitOps-Only Deployments
- **Never** kubectl apply directly to prod-cluster
- **All** changes go through ArgoCD from Git
- Enables audit trail and rollback

### 2. Separate Repositories
```
weather-app/                    # Application code
weather-app-gitops/             # Helm charts, K8s manifests
  ├── base/                     # Common configuration
  ├── prod/                     # Production overrides
  ├── dev/                      # Dev overrides
  └── staging/                  # Staging overrides
```

### 3. Image Promotion Strategy
```
1. Developer commits → GitHub
2. Jenkins builds → ECR (tag: build-123-abc123)
3. Jenkins pushes to weather-app-gitops (dev branch)
4. ArgoCD deploys to dev-cluster
5. QA approves → Merge to staging branch
6. ArgoCD deploys to staging-cluster
7. Final approval → Merge to main branch
8. ArgoCD deploys to prod-cluster
```

### 4. Monitoring and Alerts
- **Application metrics**: Exported by app, scraped by Prometheus
- **Cluster metrics**: Node exporter, kube-state-metrics
- **Deployment health**: ArgoCD webhook → n8n → Alert

### 5. Disaster Recovery
```bash
# Backup prod cluster resources
kubectl get all --all-namespaces -o yaml > backup.yaml

# In case of failure, redeploy via ArgoCD
argocd app sync weather-app-prod --force
```

## Security Checklist

- [ ] ArgoCD IRSA role has minimal EKS permissions
- [ ] Prod cluster has no External Secrets (reduced attack surface)
- [ ] Security group rules are scoped (only internal → prod)
- [ ] aws-auth ConfigMap uses custom RBAC (not system:masters)
- [ ] Application pods have no IAM roles (unless required)
- [ ] ALB Ingress uses HTTPS with ACM certificates
- [ ] Network policies restrict pod-to-pod traffic
- [ ] Image scanning enabled in ECR
- [ ] ArgoCD sync policies require approval for prod

## Next Steps

1. Deploy ArgoCD to internal-cluster (Phase 2)
2. Configure aws-auth in prod-cluster to allow ArgoCD role
3. Add prod-cluster to ArgoCD
4. Create weather-app Application manifest
5. Deploy via ArgoCD and verify
6. Set up Prometheus cross-cluster scraping
7. Create Grafana dashboards for multi-cluster visibility
