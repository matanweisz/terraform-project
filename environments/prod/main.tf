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
      Project     = var.project_name
      Environment = var.environment
      Terraform   = "true"
    }
  }
}

# Production EKS Cluster
module "eks_cluster" {
  source = "../modules/eks-cluster"

  cluster_name       = var.cluster_name
  kubernetes_version = var.kubernetes_version
  vpc_id             = local.vpc_id
  private_subnet_ids = local.private_subnet_ids

  ami_type       = var.ami_type
  instance_types = var.instance_types
  min_size       = var.min_size
  max_size       = var.max_size
  desired_size   = var.desired_size
  create_cloudwatch_log_group = var.create_cloudwatch_log_group
}

# IAM Roles for Service Accounts (IRSA)
module "irsa_roles" {
  source = "../modules/irsa-roles"

  environment       = var.environment
  project_name      = var.project_name
  aws_region        = var.aws_region
  oidc_provider_arn = module.eks_cluster.oidc_provider_arn
  oidc_provider     = module.eks_cluster.oidc_provider
}

# Cross-cluster access for ArgoCD from internal cluster
module "cluster_access" {
  source = "../modules/cluster-access"

  environment                      = var.environment
  source_cluster_security_group_id = local.internal_cluster_security_group_id
  target_cluster_security_group_id = module.eks_cluster.cluster_security_group_id
  target_node_security_group_id    = module.eks_cluster.node_security_group_id
}
