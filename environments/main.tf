terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # Shared backend for all environments
  backend "s3" {
    bucket       = "environments-terraform-state"
    key          = "terraform.tfstate"
    region       = "eu-central-1"
    use_lockfile = true
    encrypt      = true
  }
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile

  default_tags {
    tags = {
      Project   = var.project_name
      Terraform = "true"
    }
  }
}

# Dev Environment
module "dev" {
  count  = var.provision_dev ? 1 : 0
  source = "./dev"

  project_name = var.project_name
  environment  = "dev"
  aws_region   = var.aws_region
  aws_profile  = var.aws_profile

  cluster_name                = var.dev_cluster_name
  kubernetes_version          = var.dev_kubernetes_version
  instance_types              = var.dev_instance_types
  min_size                    = var.dev_min_size
  max_size                    = var.dev_max_size
  desired_size                = var.dev_desired_size
  create_cloudwatch_log_group = var.dev_create_cloudwatch_log_group
}

# Staging Environment
module "stg" {
  count  = var.provision_stg ? 1 : 0
  source = "./stg"

  project_name = var.project_name
  environment  = "staging"
  aws_region   = var.aws_region
  aws_profile  = var.aws_profile

  cluster_name                = var.stg_cluster_name
  kubernetes_version          = var.stg_kubernetes_version
  instance_types              = var.stg_instance_types
  min_size                    = var.stg_min_size
  max_size                    = var.stg_max_size
  desired_size                = var.stg_desired_size
  create_cloudwatch_log_group = var.stg_create_cloudwatch_log_group
}

# Production Environment
module "prod" {
  count  = var.provision_prod ? 1 : 0
  source = "./prod"

  project_name = var.project_name
  environment  = "prod"
  aws_region   = var.aws_region
  aws_profile  = var.aws_profile

  cluster_name                = var.prod_cluster_name
  kubernetes_version          = var.prod_kubernetes_version
  instance_types              = var.prod_instance_types
  min_size                    = var.prod_min_size
  max_size                    = var.prod_max_size
  desired_size                = var.prod_desired_size
  create_cloudwatch_log_group = var.prod_create_cloudwatch_log_group
}
