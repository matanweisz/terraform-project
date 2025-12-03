# EKS Cluster Outputs
output "cluster_id" {
  description = "The ID of the EKS cluster"
  value       = module.eks_cluster.cluster_id
}

output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = module.eks_cluster.cluster_id
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks_cluster.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = module.eks_cluster.cluster_security_group_id
}

output "cluster_primary_security_group_id" {
  description = "Cluster security group that was created by Amazon EKS for the cluster"
  value       = module.eks_cluster.cluster_primary_security_group_id
}

output "node_security_group_id" {
  description = "Security group ID attached to the EKS nodes"
  value       = module.eks_cluster.node_security_group_id
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC Provider for EKS"
  value       = module.eks_cluster.oidc_provider_arn
}

output "oidc_provider" {
  description = "OIDC Provider for EKS (without https://)"
  value       = module.eks_cluster.oidc_provider
}

# IRSA Role Outputs
output "alb_controller_role_arn" {
  description = "ARN of the IAM role for ALB controller"
  value       = module.irsa_roles.alb_controller_role_arn
}

# ECR Outputs
output "ecr_repository_url" {
  description = "URL of the ECR repository (use this in Jenkins pipeline)"
  value       = module.ecr.repository_url
}

output "ecr_repository_arn" {
  description = "ARN of the ECR repository"
  value       = module.ecr.repository_arn
}

output "ecr_repository_name" {
  description = "Name of the ECR repository"
  value       = module.ecr.repository_name
}
