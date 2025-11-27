variable "oidc_provider_arn" {
  description = "OIDC provider ARN from EKS cluster for IRSA"
  type        = string
}

variable "oidc_provider" {
  description = "OIDC provider URL (without https:// prefix)"
  type        = string
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "project_name" {
  description = "Name of the project for resource naming"
  type        = string
}

variable "aws_region" {
  description = "AWS region for policy ARNs"
  type        = string
}

variable "ecr_repository_arn" {
  description = "ARN of the ECR repository for Jenkins agent permissions"
  type        = string
}
