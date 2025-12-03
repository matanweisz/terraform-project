#!/bin/bash

# S3 Backend Setup for Environments Terraform
# Creates S3 bucket to store all environment state files (prod, stg, dev)

set -e

BUCKET_NAME="environments-terraform-state"
REGION="eu-central-1"

echo "Setting up Environments Terraform S3 backend..."
echo ""
echo "Bucket: $BUCKET_NAME"
echo "Region: $REGION"
echo ""

# Create S3 bucket
echo "Creating S3 bucket..."
aws s3api create-bucket \
    --bucket "$BUCKET_NAME" \
    --region "$REGION" \
    --create-bucket-configuration LocationConstraint="$REGION" \
    2>/dev/null || echo "Bucket already exists"

# Enable versioning
echo "Enabling versioning..."
aws s3api put-bucket-versioning \
    --bucket "$BUCKET_NAME" \
    --versioning-configuration Status=Enabled

# Enable encryption
echo "Enabling encryption..."
aws s3api put-bucket-encryption \
    --bucket "$BUCKET_NAME" \
    --server-side-encryption-configuration '{
        "Rules": [{
            "ApplyServerSideEncryptionByDefault": {
                "SSEAlgorithm": "AES256"
            }
        }]
    }'

# Block public access
echo "Blocking public access..."
aws s3api put-public-access-block \
    --bucket "$BUCKET_NAME" \
    --public-access-block-configuration \
        BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

echo ""
echo "✓ Environments backend setup complete!"
echo ""
echo "State files will be stored as:"
echo "  • s3://$BUCKET_NAME/prod/terraform.tfstate"
echo "  • s3://$BUCKET_NAME/stg/terraform.tfstate"
echo "  • s3://$BUCKET_NAME/dev/terraform.tfstate"
echo ""
echo "Next steps:"
echo "  cd terraform/environments/prod && terraform init"
echo "  cd terraform/environments/stg && terraform init"
echo "  cd terraform/environments/dev && terraform init"
