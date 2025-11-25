#!/bin/bash

set -e

BUCKET_NAME="foundation-terraform-s3-remote-state"
REGION="eu-central-1"
KEY_ALIAS="alias/$BUCKET_NAME-key"

echo "Setting up Terraform remote backend for CI/CD project..."

if ! aws s3 ls "s3://$BUCKET_NAME" 2>/dev/null; then
    echo "Creating S3 bucket: $BUCKET_NAME"
    aws s3api create-bucket \
        --bucket $BUCKET_NAME \
        --region $REGION \
        --create-bucket-configuration LocationConstraint=$REGION
fi

echo "Enabling bucket versioning..."
aws s3api put-bucket-versioning \
    --bucket $BUCKET_NAME \
    --versioning-configuration Status=Enabled

echo "Blocking public access to S3 bucket..."
aws s3api put-public-access-block \
    --bucket $BUCKET_NAME \
    --public-access-block-configuration \
    BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

echo "Checking for KMS key..."
KEY_ID=$(aws kms list-aliases --query "Aliases[?AliasName=='$KEY_ALIAS'].TargetKeyId" --output text)

if [ -z "$KEY_ID" ]; then
    echo "Creating KMS key for state encryption..."
    KEY_ID=$(aws kms create-key \
        --description "Terraform state encryption key for CI/CD project" \
        --query 'KeyMetadata.KeyId' \
        --output text)

    aws kms create-alias \
        --alias-name $KEY_ALIAS \
        --target-key-id $KEY_ID
else
    echo "KMS key already exists."
fi

echo "Backend setup complete!"
