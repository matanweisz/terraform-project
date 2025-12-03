# Environment Orchestrator

This directory contains the orchestrator that manages all environments (dev, staging, production) from a single Terraform configuration.

## Architecture

```
terraform/environments/
├── main.tf                    # Orchestrator - provisions environments based on toggles
├── variables.tf               # Configuration for all environments
├── outputs.tf                 # Outputs from provisioned environments
├── locals.tf                  # Local values and helpers
├── terraform.tfvars.example   # Example configuration
├── dev/                       # Dev environment module
├── stg/                       # Staging environment module
├── prod/                      # Production environment module
└── modules/                   # Shared Terraform modules
    ├── cluster-access/
    ├── eks-cluster/
    └── irsa-roles/
```

## Quick Start

### 1. Create Backend Bucket

First, ensure the backend S3 bucket exists:

```bash
cd ../backend
terraform init
terraform apply
```

This creates the `environments-terraform-s3-remote-state` bucket.

### 2. Configure Environments

Copy the example configuration:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` to enable/disable environments:

```hcl
# Toggle environments
provision_dev  = true
provision_stg  = true
provision_prod = false

# Configure each environment
dev_cluster_name = "dev-eks-cluster"
dev_min_size     = 1
dev_max_size     = 2
dev_desired_size = 1

stg_cluster_name = "stg-eks-cluster"
stg_min_size     = 1
stg_max_size     = 3
stg_desired_size = 2

prod_cluster_name = "prod-eks-cluster"
prod_min_size     = 2
prod_max_size     = 5
prod_desired_size = 3
```

### 3. Deploy Environments

```bash
terraform init
terraform plan
terraform apply
```

Terraform will only provision environments where `provision_<env> = true`.

## How It Works

### Single State File

All environments are managed in a single state file stored in `environments-terraform-s3-remote-state`. This simplifies management and allows you to see all environments at once.

### Conditional Provisioning

Each environment module uses `count` to conditionally create resources:

```hcl
module "dev" {
  count  = var.provision_dev ? 1 : 0
  source = "./dev"
  # ... configuration
}
```

When `provision_dev = false`, the module is not created. When `true`, it's instantiated.

### Toggle Workflow

1. Edit `terraform.tfvars` to change `provision_<env>` flags
2. Run `terraform plan` to see what will change
3. Run `terraform apply` to apply changes

**Enabling an environment**: Set `provision_<env> = true` and apply
**Disabling an environment**: Set `provision_<env> = false` and apply (destroys the environment!)

## Variables

All variables are defined in `variables.tf`. Key variables:

### Global Settings
- `project_name`: Project name (default: "weather-app")
- `aws_region`: AWS region (default: "eu-central-1")
- `aws_profile`: AWS CLI profile (default: "default")

### Environment Toggles
- `provision_dev`: Enable/disable dev environment (default: false)
- `provision_stg`: Enable/disable staging environment (default: false)
- `provision_prod`: Enable/disable production environment (default: false)

### Per-Environment Settings
Each environment has its own set of variables:
- `<env>_cluster_name`: EKS cluster name
- `<env>_kubernetes_version`: Kubernetes version
- `<env>_instance_types`: Node instance types
- `<env>_min_size`: Minimum nodes
- `<env>_max_size`: Maximum nodes
- `<env>_desired_size`: Desired nodes
- `<env>_create_cloudwatch_log_group`: CloudWatch logging

## Outputs

Run `terraform output` to see:
- `provisioned_environments`: List of active environments
- `dev_cluster_endpoint`: Dev cluster endpoint (if provisioned)
- `dev_cluster_name`: Dev cluster name (if provisioned)
- `stg_cluster_endpoint`: Staging cluster endpoint (if provisioned)
- `stg_cluster_name`: Staging cluster name (if provisioned)
- `prod_cluster_endpoint`: Production cluster endpoint (if provisioned)
- `prod_cluster_name`: Production cluster name (if provisioned)

## Best Practices

### 1. Test Changes in Dev First
Always test infrastructure changes in dev before applying to staging or production.

### 2. Review Plans Carefully
Always review `terraform plan` output before applying, especially when disabling environments.

### 3. Use Version Control
Commit `terraform.tfvars` to version control to track which environments should be provisioned.

## Common Operations

### Enable a New Environment

```hcl
# In terraform.tfvars
provision_dev = true
```

```bash
terraform apply
```

### Disable an Environment

**Warning**: This destroys all resources in that environment!

```hcl
# In terraform.tfvars
provision_dev = false
```

```bash
terraform plan  # Verify what will be destroyed
terraform apply
```

### Update Environment Configuration

```hcl
# In terraform.tfvars
dev_min_size     = 2  # Changed from 1
dev_max_size     = 4  # Changed from 2
dev_desired_size = 2  # Changed from 1
```

```bash
terraform apply
```

## Troubleshooting

### "Backend bucket does not exist"
Run `cd ../backend && terraform apply` to create the backend bucket.

### "Error acquiring state lock"
Another Terraform process is running. Wait for it to complete.

### "Module not found"
Run `terraform init` to download modules.

## Directory Structure

Each environment directory (dev/, stg/, prod/) contains:
- `main.tf` - Provider config and module calls
- `variables.tf` - Environment-specific variables
- `data.tf` - Remote state data sources (reads foundation outputs)
- `outputs.tf` - Environment outputs

Shared modules are in the `modules/` directory:
- `cluster-access/` - Cross-cluster security group rules
- `eks-cluster/` - EKS cluster configuration
- `irsa-roles/` - IAM Roles for Service Accounts

## Next Steps

After provisioning environments:
1. Configure kubectl access to each cluster
2. Deploy applications via ArgoCD
3. Set up monitoring and observability
4. Configure CI/CD pipelines
