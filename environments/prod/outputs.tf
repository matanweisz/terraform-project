# Production EKS Cluster Outputs
output "prod_cluster_id" {
  description = "The ID/name of the production EKS cluster"
  value       = module.eks_cluster.cluster_id
}

output "prod_cluster_arn" {
  description = "The ARN of the production EKS cluster"
  value       = module.eks_cluster.cluster_arn
}

output "prod_cluster_endpoint" {
  description = "Endpoint for production EKS cluster API server"
  value       = module.eks_cluster.cluster_endpoint
}

output "prod_cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data for cluster authentication"
  value       = module.eks_cluster.cluster_certificate_authority_data
  sensitive   = true
}

output "prod_cluster_security_group_id" {
  description = "Security group ID attached to the production EKS cluster (Terraform-managed)"
  value       = module.eks_cluster.cluster_security_group_id
}

output "prod_cluster_primary_security_group_id" {
  description = "EKS-managed security group that controls access to the Kubernetes API endpoint"
  value       = module.eks_cluster.cluster_primary_security_group_id
}

output "prod_node_security_group_id" {
  description = "Security group ID attached to the production EKS nodes"
  value       = module.eks_cluster.node_security_group_id
}

output "prod_cluster_oidc_provider_arn" {
  description = "ARN of the OIDC provider for IRSA"
  value       = module.eks_cluster.oidc_provider_arn
}

output "prod_cluster_version" {
  description = "The Kubernetes version running on the production cluster"
  value       = module.eks_cluster.cluster_version
}

# IAM Role Outputs
output "alb_controller_role_arn" {
  description = "ARN of ALB Ingress Controller IAM role (annotate ServiceAccount with this)"
  value       = module.irsa_roles.alb_controller_role_arn
}

# Cluster Access Outputs
output "cluster_access_configured" {
  description = "Indicates that cross-cluster access from internal cluster is configured"
  value       = true
}

# Summary Output
output "environment_summary" {
  description = "Summary of production environment resources"
  value = {
    environment             = var.environment
    cluster_name            = module.eks_cluster.cluster_id
    cluster_endpoint        = module.eks_cluster.cluster_endpoint
    alb_controller_role_arn = module.irsa_roles.alb_controller_role_arn
    vpc_id                  = local.vpc_id
    cross_cluster_access    = "enabled-from-internal-cluster"
  }
}
