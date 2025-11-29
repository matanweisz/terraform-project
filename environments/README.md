# Environments Layer - Production Terraform Configuration

This directory contains the **environments layer** of the two-layer Terraform architecture. It manages environment-specific EKS clusters (prod, dev, staging) that run application workloads.

## Architecture Overview

### Two-Layer Terraform Strategy

```
Layer 1: Foundation (manual)       Layer 2: Environments (automated)
├── VPC                            ├── prod-cluster (EKS)
├── internal-cluster (EKS)         ├── dev-cluster (EKS) - future
├── IAM roles (foundation)         ├── staging-cluster (EKS) - future
├── ECR repository                 ├── IAM roles (environment-specific)
└── Secrets Manager                └── Security group rules
```

**Key principle**: Foundation provides networking and shared resources. Environments consume those resources via remote state and create their own clusters.

## Directory Structure

```
environments/
├── modules/                  # Reusable modules for all environments
│   ├── eks-cluster/         # EKS cluster wrapper module
│   │   ├── main.tf          # Wraps terraform-aws-modules/eks
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── irsa-roles/          # IAM Roles for Service Accounts
│   │   ├── main.tf          # ALB controller, External Secrets
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── policies/        # IAM policy JSON files
│   │       └── alb-controller.json
│   └── cluster-access/      # Cross-cluster security group rules
│       ├── main.tf          # Allow internal-cluster → env-cluster
│       ├── variables.tf
│       └── outputs.tf
├── prod/                    # Production environment
│   ├── backend.tf           # S3 backend configuration
│   ├── data.tf              # Remote state data source (foundation)
│   ├── main.tf              # Main environment configuration
│   ├── variables.tf         # Environment variables
│   ├── terraform.tfvars     # Production values
│   └── outputs.tf           # Environment outputs
└── README.md                # This file
```

## Module Descriptions

### 1. `modules/eks-cluster`

Reusable EKS cluster module that wraps the official `terraform-aws-modules/eks` module with sensible defaults.

**Features**:
- EKS cluster with managed node groups
- Core addons (CoreDNS, kube-proxy, VPC-CNI, Pod Identity Agent)
- IRSA (IAM Roles for Service Accounts) enabled
- Public endpoint for ALB access

**Usage**:
```hcl
module "eks_cluster" {
  source = "../modules/eks-cluster"

  cluster_name       = "prod-cluster"
  kubernetes_version = "1.34"
  vpc_id             = local.vpc_id
  private_subnet_ids = local.private_subnet_ids
  ami_type           = "AL2023_x86_64_STANDARD"
  instance_types     = ["t3.medium"]
  min_size           = 1
  max_size           = 2
  desired_size       = 1
}
```

### 2. `modules/irsa-roles`

Creates IAM roles for Kubernetes service accounts to access AWS services.

**Roles created**:
- **ALB Controller**: Manages Application Load Balancers for Ingress

**Note**: External Secrets Operator is NOT deployed in production environments to maintain a minimal security surface. Application secrets should be baked into container images or managed via ArgoCD.

**Usage**:
```hcl
module "irsa_roles" {
  source = "../modules/irsa-roles"

  environment       = "prod"
  project_name      = "weather-app"
  aws_region        = "eu-central-1"
  oidc_provider_arn = module.eks_cluster.oidc_provider_arn
  oidc_provider     = module.eks_cluster.oidc_provider
}
```

**Output**: IAM role ARNs to annotate Kubernetes ServiceAccounts:
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: aws-load-balancer-controller
  namespace: kube-system
  annotations:
    eks.amazonaws.com/role-arn: <alb_controller_role_arn>
```

### 3. `modules/cluster-access`

Configures security group rules to allow cross-cluster communication from the internal cluster to environment clusters.

**Purpose**: Enables ArgoCD running in `internal-cluster` to manage applications in `prod-cluster`.

**Security rules created**:
- Allow internal cluster → prod cluster API (port 443)
- Allow internal cluster → prod cluster nodes (all TCP)
- Allow response traffic back to internal cluster

**Usage**:
```hcl
module "cluster_access" {
  source = "../modules/cluster-access"

  environment                      = "prod"
  source_cluster_security_group_id = local.internal_cluster_security_group_id
  target_cluster_security_group_id = module.eks_cluster.cluster_security_group_id
  target_node_security_group_id    = module.eks_cluster.node_security_group_id
}
```

## Production Environment (`prod/`)

### Remote State Integration

The `data.tf` file reads outputs from the foundation layer:

```hcl
data "terraform_remote_state" "foundation" {
  backend = "s3"
  config = {
    bucket = "foundation-terraform-s3-remote-state"
    key    = "terraform.tfstate"
    region = "eu-central-1"
  }
}

locals {
  vpc_id                             = data.terraform_remote_state.foundation.outputs.vpc_id
  private_subnet_ids                 = data.terraform_remote_state.foundation.outputs.private_subnet_ids
  internal_cluster_security_group_id = data.terraform_remote_state.foundation.outputs.internal_cluster_security_group_id
  # ... more outputs
}
```

**Why this matters**: No hardcoded VPC IDs. Changes to foundation automatically propagate to environments.

### Configuration Files

#### `backend.tf`
Separate S3 backend for environment state isolation:
```hcl
terraform {
  backend "s3" {
    bucket       = "prod-terraform-s3-remote-state"
    key          = "terraform.tfstate"
    region       = "eu-central-1"
    use_lockfile = true
    encrypt      = true
  }
}
```

#### `terraform.tfvars`
Production-specific values:
```hcl
environment        = "prod"
cluster_name       = "prod-cluster"
kubernetes_version = "1.34"
ami_type           = "AL2023_x86_64_STANDARD"
instance_types     = ["t3.medium"]
min_size           = 1
max_size           = 2
desired_size       = 1
```

## Usage Instructions

### Prerequisites

1. Foundation layer must be applied and working
2. S3 bucket for prod backend must exist: `prod-terraform-s3-remote-state`
3. AWS credentials configured with profile: `full-project-user`

### Deploying Production Environment

```bash
cd terraform/environments/prod

# Initialize Terraform (first time only)
terraform init

# Review planned changes
terraform plan

# Apply configuration
terraform apply

# View outputs
terraform output
```

### Accessing the Cluster

```bash
# Configure kubectl
aws eks update-kubeconfig \
  --region eu-central-1 \
  --name prod-cluster \
  --profile full-project-user

# Verify access
kubectl get nodes
kubectl get namespaces
```

### Deploying ALB Ingress Controller

After cluster creation, deploy the ALB controller with the IRSA role:

```bash
# Get the role ARN
ROLE_ARN=$(terraform output -raw alb_controller_role_arn)

# Install ALB controller via Helm
helm repo add eks https://aws.github.io/eks-charts
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=prod-cluster \
  --set serviceAccount.create=true \
  --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=$ROLE_ARN
```

## Adding New Environments (dev/staging)

To add a new environment, copy the `prod/` directory structure:

```bash
# Create new environment
cp -r prod/ dev/

# Update the following files:
# - backend.tf: Change bucket to "dev-terraform-s3-remote-state"
# - terraform.tfvars: Change cluster_name to "dev-cluster", environment to "dev"

# Initialize and apply
cd dev/
terraform init
terraform plan
terraform apply
```

## Cost Optimization

**Production cluster cost**: ~$150/month
- EKS control plane: ~$73/month
- t3.medium nodes (1-2): ~$60-120/month

**To destroy when not in use**:
```bash
cd terraform/environments/prod
terraform destroy
```

**Note**: Destroying prod cluster does NOT affect foundation layer (VPC, internal-cluster, ECR).

## Validation and Testing

### Validate Configuration

```bash
terraform validate
terraform fmt -recursive
```

### Test Cross-Cluster Access

```bash
# From internal cluster, test prod cluster access
kubectl config use-context internal-cluster
kubectl --context prod-cluster get nodes

# Should work if security groups are correctly configured
```

### Verify IAM Roles

```bash
# Check role trust policy
aws iam get-role --role-name prod-weather-app-alb-controller

# Verify OIDC provider
aws iam list-open-id-connect-providers
```

## Best Practices

### 1. Never Hardcode Values
- Use `data.tf` to retrieve foundation outputs
- Use variables for environment-specific values

### 2. Module Reusability
- Create modules for patterns used across environments
- Keep modules simple and single-purpose

### 3. State Isolation
- Each environment has its own S3 backend
- Foundation and environments have separate state files

### 4. Security
- Security groups configured via modules
- IAM roles follow least-privilege principle
- Secrets stored in AWS Secrets Manager (not Terraform state)

### 5. Documentation
- Update README when adding new modules
- Document architectural decisions
- Include usage examples

## Troubleshooting

### Error: "No module call named 'vpc'"
**Cause**: Missing `data.tf` or incorrect remote state configuration.
**Fix**: Ensure `data.tf` exists and foundation backend is correct.

### Error: "Error creating Security Group Rule"
**Cause**: Source security group doesn't exist.
**Fix**: Verify foundation layer outputs include `internal_cluster_security_group_id`.

### Error: "InvalidParameterException: Cluster does not exist"
**Cause**: Cluster name mismatch.
**Fix**: Ensure `cluster_name` in terraform.tfvars matches the actual cluster name.

## Next Steps

After deploying the production environment:

1. **Deploy ALB Ingress Controller** (see instructions above)
2. **Deploy External Secrets Operator** for secrets management
3. **Configure ArgoCD** in internal cluster to manage prod applications
4. **Deploy weather-app** via ArgoCD GitOps workflow
5. **Set up monitoring** with Prometheus and Grafana

## References

- [Terraform AWS EKS Module](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws)
- [AWS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/)
- [IRSA Documentation](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html)
- [Two-Layer Terraform Strategy](../../docs/TERRAFORM_LAYERING_STRATEGY.md)
