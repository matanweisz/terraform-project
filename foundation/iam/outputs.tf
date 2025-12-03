output "alb_controller_role_arn" {
  description = "ARN of ALB controller IAM role (annotate ServiceAccount: eks.amazonaws.com/role-arn)"
  value       = aws_iam_role.alb_controller.arn
}

output "alb_controller_role_name" {
  description = "Name of ALB controller IAM role"
  value       = aws_iam_role.alb_controller.name
}

output "jenkins_ecr_role_arn" {
  description = "ARN of Jenkins IAM role for ECR push to all environments (annotate ServiceAccount with this)"
  value       = aws_iam_role.jenkins_ecr.arn
}

output "jenkins_ecr_role_name" {
  description = "Name of Jenkins IAM role"
  value       = aws_iam_role.jenkins_ecr.name
}

output "argocd_role_arn" {
  description = "ARN of ArgoCD IAM role for Secrets Manager (annotate ServiceAccount: eks.amazonaws.com/role-arn)"
  value       = aws_iam_role.argocd.arn
}

output "argocd_role_name" {
  description = "Name of ArgoCD IAM role"
  value       = aws_iam_role.argocd.name
}

output "external_secrets_role_arn" {
  description = "ARN of External Secrets Operator IAM role (annotate ServiceAccount: eks.amazonaws.com/role-arn)"
  value       = aws_iam_role.external_secrets.arn
}

output "external_secrets_role_name" {
  description = "Name of External Secrets Operator IAM role"
  value       = aws_iam_role.external_secrets.name
}

output "ebs_csi_driver_role_arn" {
  description = "ARN of EBS CSI Driver IAM role (annotate ServiceAccount: eks.amazonaws.com/role-arn)"
  value       = aws_iam_role.ebs_csi_driver.arn
}
