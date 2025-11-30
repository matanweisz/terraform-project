# Foundation Layer Configuration

# Global Configuration
aws_region   = "eu-central-1"
aws_profile  = "full-project-user"
project_name = "foundation-terraform-project"

# VPC Configuration
vpc_cidr             = "10.0.0.0/16"
private_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
public_subnet_cidrs  = ["10.0.10.0/24", "10.0.20.0/24", "10.0.30.0/24"]

# EKS Cluster Configuration
cluster_name                    = "internal-cluster"
kubernetes_version              = "1.34"
eks_create_cloudwatch_log_group = false

# EKS Node Group Configuration
ami_type       = "AL2023_x86_64_STANDARD"
instance_types = ["t3.medium"]
min_size       = 2
max_size       = 4
desired_size   = 3

# ECR Configuration
ecr_repository_name      = "weather-app"
ecr_image_tag_mutability = "MUTABLE"
ecr_scan_on_push         = true
ecr_max_image_count      = 10
