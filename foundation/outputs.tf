# Foundation Layer Outputs

# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC for use by environment clusters"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "private_subnet_ids" {
  description = "List of private subnet IDs for EKS node groups"
  value       = module.vpc.private_subnet_ids
}

output "public_subnet_ids" {
  description = "List of public subnet IDs for ALB"
  value       = module.vpc.public_subnet_ids
}

# Internal EKS Cluster Outputs
output "internal_cluster_name" {
  description = "Name of the internal EKS cluster"
  value       = module.eks.cluster_id
}

output "internal_cluster_endpoint" {
  description = "Endpoint for internal EKS cluster API server"
  value       = module.eks.cluster_endpoint
}

output "internal_cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data for cluster authentication"
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

output "internal_cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = module.eks.cluster_security_group_id
}

output "internal_cluster_oidc_provider_arn" {
  description = "OIDC provider ARN for IRSA (IAM Roles for Service Accounts)"
  value       = module.eks.oidc_provider_arn
}

# IAM Role Outputs
output "alb_controller_role_arn" {
  description = "ARN of ALB Ingress Controller IAM role (annotate ServiceAccount with this)"
  value       = module.iam.alb_controller_role_arn
}

output "jenkins_ecr_role_arn" {
  description = "ARN of Jenkins IAM role for ECR push (annotate ServiceAccount with this)"
  value       = module.iam.jenkins_ecr_role_arn
}

output "argocd_role_arn" {
  description = "ARN of ArgoCD IAM role for Secrets Manager access (annotate ServiceAccount with this)"
  value       = module.iam.argocd_role_arn
}

output "external_secrets_role_arn" {
  description = "ARN of External Secrets Operator IAM role (annotate ServiceAccount with this)"
  value       = module.iam.external_secrets_role_arn
}

output "ebs_csi_driver_role_arn" {
  description = "ARN of EBS CSI Driver IAM role (annotate ServiceAccount with this)"
  value       = module.iam.ebs_csi_driver_role_arn
}

# ECR Outputs
output "ecr_repository_url" {
  description = "ECR repository URL for weather-app container images (use in Jenkins pipeline)"
  value       = module.ecr.repository_url
}

output "ecr_repository_arn" {
  description = "ECR repository ARN"
  value       = module.ecr.repository_arn
}

output "ecr_repository_name" {
  description = "ECR repository name"
  value       = module.ecr.repository_name
}

# Secrets Manager Outputs
output "secret_names" {
  description = "List of all secret names created in AWS Secrets Manager"
  value       = module.secret_manager.secret_names
}

output "manual_injection_commands" {
  description = "AWS CLI commands to manually inject secret values into AWS Secrets Manager"
  value       = module.secret_manager.manual_injection_commands
  sensitive   = false # Not sensitive - these are just placeholder commands
}

# Summary Output of all created resources
output "foundation_summary" {
  description = "Summary of foundation resources created"
  value = {
    vpc_id                    = module.vpc.vpc_id
    cluster_name              = module.eks.cluster_id
    cluster_endpoint          = module.eks.cluster_endpoint
    ecr_repository            = module.ecr.repository_url
    external_secrets_role_arn = module.iam.external_secrets_role_arn
  }
}
