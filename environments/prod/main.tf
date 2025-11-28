terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile

  default_tags {
    tags = {
      Project   = var.project_name
      Terraform = "true"
      Env       = "prod"
    }
  }
}

# Create EKS Cluster
module "eks" {
  source = "../../foundation/eks"

  cluster_name       = var.cluster_name
  kubernetes_version = var.kubernetes_version
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  ami_type           = var.ami_type
  instance_types     = var.instance_types
  min_size           = var.min_size
  max_size           = var.max_size
  desired_size       = var.desired_size
}
