# Foundation Layer - Terraform Infrastructure

---

## Quick Start

```bash
# Navigate to foundation directory
cd /home/matanweisz/git/matan-github/full-project/terraform/foundation

# Initialize Terraform
terraform init

# Review what will be created
terraform plan

# Deploy infrastructure (takes ~15-20 minutes)
terraform apply

# Verify deployment
kubectl get nodes
```

---

## What This Terraform project Creates

This foundation layer creates the core infrastructure for a multi-cluster Kubernetes platform:

| Component          | Description                                  | Cost/Month      |
| ------------------ | -------------------------------------------- | --------------- |
| **VPC**            | Multi-AZ network with public/private subnets | $0              |
| **NAT Gateway**    | Internet access for private subnets          | $32             |
| **EKS Cluster**    | Kubernetes 1.34 control plane                | $73             |
| **EKS Nodes**      | 2x t4g.medium ARM instances                  | ~$48            |
| **IAM Roles**      | IRSA for ALB, Jenkins, ArgoCD                | $0              |
| **ECR Repository** | Container image registry                     | ~$1             |
| **Total**          |                                              | **~$154/month** |

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  Region: eu-central-1                                        │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  VPC (10.0.0.0/16)                                          │
│  ┌────────────────────────────────────────────────────┐    │
│  │  AZ-a            AZ-b            AZ-c               │    │
│  │  ────────────    ────────────    ────────────      │    │
│  │  Public /24      Public /24      Public /24        │    │
│  │  Private /24     Private /24     Private /24       │    │
│  └────────────────────────────────────────────────────┘    │
│                         ▲                                    │
│                         │                                    │
│  EKS Cluster: internal-cluster (v1.34)                      │
│  ┌────────────────────────────────────────────────────┐    │
│  │  Node Group: t4g.medium ARM instances              │    │
│  │  Min: 1  |  Desired: 2  |  Max: 3                  │    │
│  │                                                      │    │
│  │  Services (future):                                 │    │
│  │  - Jenkins (CI)                                     │    │
│  │  - ArgoCD (CD)                                      │    │
│  │  - Grafana (Observability)                          │    │
│  │  - Prometheus (Metrics)                             │    │
│  │  - n8n (AI Workflow)                                │    │
│  └────────────────────────────────────────────────────┘    │
│                                                              │
│  ECR Repository: weather-app                                │
│  - Scanning: Enabled                                        │
│  - Max images: 30                                           │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## Module Structure

```
foundation/
├── main.tf                 # Root orchestrator
├── variables.tf            # Configuration options
├── terraform.tfvars        # Your specific settings
├── outputs.tf              # Exported values
├── backend.tf              # S3 state storage
│
├── vpc/                    # VPC module
├── eks/                    # EKS cluster module
├── iam/                    # IRSA roles module
└── ecr/                    # Container registry module
```

---

## Post-Deployment Steps

### 1. Configure kubectl

```bash
aws eks update-kubeconfig \
  --name $(terraform output -raw internal_cluster_name) \
  --region eu-central-1

# Verify
kubectl get nodes
kubectl get pods -A
```

### 2. Verify IAM Roles

```bash
# List created roles
aws iam list-roles --query 'Roles[?contains(RoleName, `foundation-terraform-project`)].RoleName'

# Check role trust policy
aws iam get-role --role-name foundation-terraform-project-jenkins-agent \
  --query 'Role.AssumeRolePolicyDocument'
```

### 3. Verify ECR

```bash
# Describe repository
aws ecr describe-repositories --repository-names weather-app

# Test login (for future pushes)
aws ecr get-login-password --region eu-central-1 | \
  docker login --username AWS --password-stdin $(terraform output -raw ecr_repository_url | cut -d/ -f1)
```

---

## Updating Infrastructure

### Modifying Configuration

1. Edit `terraform.tfvars`
2. Review changes: `terraform plan`
3. Apply: `terraform apply`

### Scaling Nodes

```hcl
# In terraform.tfvars
desired_size = 3  # Scale up to 3 nodes
```

```bash
terraform apply
```

### Adding IRSA Roles

1. Add role in `iam/main.tf`
2. Add policy in `iam/policies/`
3. Export in `iam/outputs.tf`
4. Export in root `outputs.tf`
5. Apply: `terraform apply`

---

## Troubleshooting

### Issue: Nodes not joining cluster

**Check**:

```bash
# Node group status
aws eks describe-nodegroup \
  --cluster-name internal-cluster \
  --nodegroup-name internal

# EC2 instances
aws ec2 describe-instances \
  --filters "Name=tag:eks:cluster-name,Values=internal-cluster"
```

**Common causes**:

- Security group misconfiguration
- Subnet tags missing
- IAM role permissions

### Issue: OIDC provider errors

**Solution**: OIDC provider takes ~60 seconds to propagate after EKS creation

```bash
# Wait, then retry
sleep 60
terraform apply
```

### Issue: State lock errors

**Check**:

```bash
# List locks
aws s3 ls s3://foundation-terraform-s3-remote-state/

# If stale lock exists (use with caution)
aws s3 rm s3://foundation-terraform-s3-remote-state/.tfstate.lock
```
