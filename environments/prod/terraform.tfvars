# Global Configuration
aws_region   = "eu-central-1"
aws_profile  = "full-project-user"
project_name = "weather-app-prod"

# EKS Cluster Configuration
cluster_name       = "prod-cluster"
kubernetes_version = "1.34"

# EKS Node Group Configuration
ami_type       = "AL2023_x86_64_STANDARD"
instance_types = ["t3.medium"]
min_size       = 1
max_size       = 2
desired_size   = 1

# VPC Configuration (from foundation layer)
vpc_id             = "vpc-0a0b0c0d0e0f0g0h"
private_subnet_ids = ["subnet-0a0b0c0d0e0f0g0h", "subnet-0a0b0c0d0e0f0g0h", "subnet-0a0b0c0d0e0f0g0h"]
