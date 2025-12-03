# Terraform Infrastructure

Simple Terraform setup for multi-environment EKS infrastructure.

## Structure

```
terraform/
├── foundation/                  # Shared infrastructure
│   ├── scripts/
│   │   └── setup-backend.sh    # Creates foundation S3 bucket
│   ├── backend.tf
│   └── ...
└── environments/               # Environment-specific clusters
    ├── scripts/
    │   └── setup-backends.sh   # Creates environments S3 bucket
    ├── prod/
    │   ├── backend.tf
    │   ├── data.tf
    │   └── main.tf
    ├── stg/
    └── dev/
```

## Quick Start

### 1. Setup Backends (One-time)

```bash
# Foundation backend
cd terraform/foundation/scripts
./setup-backend.sh

# Environments backend
cd ../../environments/scripts
./setup-backends.sh
```

This creates two S3 buckets:
- `foundation-terraform-state` - For foundation infrastructure
- `environments-terraform-state` - For all environment clusters

Both with versioning, encryption, and blocked public access.

### 2. Deploy Foundation

```bash
cd terraform/foundation
terraform init
terraform apply
```

### 3. Deploy Environments

```bash
# Production
cd terraform/environments/prod
terraform init
terraform apply

# Staging
cd ../stg
terraform init
terraform apply

# Development
cd ../dev
terraform init
terraform apply
```

## State File Storage

State files are stored in two separate S3 buckets:

| Component | State File Location |
|-----------|-------------------|
| Foundation | `s3://foundation-terraform-state/terraform.tfstate` |
| Production | `s3://environments-terraform-state/prod/terraform.tfstate` |
| Staging | `s3://environments-terraform-state/stg/terraform.tfstate` |
| Development | `s3://environments-terraform-state/dev/terraform.tfstate` |

## Common Commands

```bash
# Initialize
terraform init

# Plan changes
terraform plan

# Apply changes
terraform apply

# Destroy resources
terraform destroy

# Show outputs
terraform output

# Format code
terraform fmt -recursive
```

## Migrating Existing State

If you already have state files in the old bucket, migrate them:

```bash
# For foundation
cd terraform/foundation
terraform init -migrate-state

# For each environment
cd terraform/environments/prod
terraform init -migrate-state
```

Terraform will prompt you to confirm the migration.

## Notes

- Backend configuration is in each directory's `backend.tf`
- All environments share the same S3 bucket
- State files are encrypted at rest
- Versioning allows rollback if needed
