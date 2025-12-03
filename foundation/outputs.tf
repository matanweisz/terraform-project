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

output "internal_cluster_node_security_group_id" {
  description = "Security group ID attached to the EKS nodes (where pods run)"
  value       = module.eks.node_security_group_id
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
  description = "ARN of Jenkins IAM role for ECR push to all environments (annotate Jenkins ServiceAccount with this)"
  value       = module.iam.jenkins_ecr_role_arn
}

output "argocd_role_arn" {
  description = "ARN of ArgoCD IAM role for Secrets Manager and ECR access (annotate ServiceAccount with this)"
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

# # SES Outputs
# output "route53_zone_id" {
#   description = "Route53 hosted zone ID for the domain"
#   value       = module.ses.route53_zone_id
# }
#
# output "route53_name_servers" {
#   description = "Route53 name servers - update these in your domain registrar"
#   value       = module.ses.route53_name_servers
# }
#
# output "ses_domain_identity_arn" {
#   description = "SES domain identity ARN"
#   value       = module.ses.ses_domain_identity_arn
# }
#
# output "ses_notifications_email" {
#   description = "Verified email address for ArgoCD notifications"
#   value       = module.ses.notifications_email
# }
#
# output "ses_smtp_endpoint" {
#   description = "SES SMTP endpoint for sending emails"
#   value       = module.ses.smtp_endpoint
# }

# Summary Output of all created resources
output "foundation_summary" {
  description = "Summary of foundation resources created"
  value = {
    vpc_id                    = module.vpc.vpc_id
    cluster_name              = module.eks.cluster_id
    cluster_endpoint          = module.eks.cluster_endpoint
    external_secrets_role_arn = module.iam.external_secrets_role_arn
  }
}
