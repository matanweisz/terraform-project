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
      Env       = "foundation"
    }
  }
}

# VPC Module
module "vpc" {
  source = "./vpc"

  vpc_name             = "${var.project_name}-vpc"
  vpc_cidr             = var.vpc_cidr
  private_subnet_cidrs = var.private_subnet_cidrs
  public_subnet_cidrs  = var.public_subnet_cidrs

  aws_region   = var.aws_region
  cluster_name = var.cluster_name
}

# Internal EKS Cluster Module
module "eks" {
  source = "./eks"

  cluster_name                = var.cluster_name
  kubernetes_version          = var.kubernetes_version
  vpc_id                      = module.vpc.vpc_id
  private_subnet_ids          = module.vpc.private_subnet_ids
  ami_type                    = var.ami_type
  instance_types              = var.instance_types
  min_size                    = var.min_size
  max_size                    = var.max_size
  desired_size                = var.desired_size
  create_cloudwatch_log_group = var.eks_create_cloudwatch_log_group
}

# IAM Module (IRSA Roles)
module "iam" {
  source = "./iam"

  oidc_provider_arn  = module.eks.oidc_provider_arn
  oidc_provider      = module.eks.oidc_provider
  cluster_name       = var.cluster_name
  project_name       = var.project_name
  aws_region         = var.aws_region
  ecr_repository_arn = module.ecr.repository_arn
}

# ECR Module
module "ecr" {
  source = "./ecr"

  repository_name      = var.ecr_repository_name
  image_tag_mutability = var.ecr_image_tag_mutability
  scan_on_push         = var.ecr_scan_on_push
  max_image_count      = var.ecr_max_image_count
}

# Secrets Manager Module
module "secret_manager" {
  source = "./secret-manager"

  cluster_name = var.cluster_name
}

# AWS SES domain
resource "aws_ses_domain_identity" "domain" {
  domain = "matanweisz.xyz"
}

resource "aws_route53_record" "example_amazonses_verification_record" {
  zone_id = "Z05390121UUOTTC1Z62MR"
  name    = "_amazonses.matanweisz.xyz"
  type    = "TXT"
  ttl     = "600"
  records = [aws_ses_domain_identity.domain.verification_token]
}
