#!/bin/bash

# S3 Backend Setup for Foundation Terraform
# Creates S3 bucket to store foundation state file

set -e

BUCKET_NAME="foundation-terraform-state"
REGION="eu-central-1"

echo "Setting up Foundation Terraform S3 backend..."
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
echo "✓ Foundation backend setup complete!"
echo ""
echo "State file: s3://$BUCKET_NAME/terraform.tfstate"
echo ""
echo "Next step:"
echo "  cd terraform/foundation && terraform init"
