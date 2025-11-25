# Global variables
aws_region   = "eu-central-1"
aws_profile  = "full-project-user"
project_name = "foundation-terraform-project"

# VPC variables
vpc_cidr             = "10.0.0.0/16"
private_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
public_subnet_cidrs  = ["10.0.10.0/24", "10.0.20.0/24", "10.0.30.0/24"]

# EKS cluster variables
cluster_name       = "internal-cluster"
kubernetes_version = "1.34"

# EKS node group variables
ami_type       = "AL2023_x86_64_STANDARD"
instance_types = ["t4g.medium"]
min_size       = 1
max_size       = 3
desired_size   = 2


