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

