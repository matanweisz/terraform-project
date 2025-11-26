output "alb_controller_role_arn" {
  description = "ARN of ALB controller IAM role (annotate ServiceAccount: eks.amazonaws.com/role-arn)"
  value       = aws_iam_role.alb_controller.arn
}

output "alb_controller_role_name" {
  description = "Name of ALB controller IAM role"
  value       = aws_iam_role.alb_controller.name
}

output "jenkins_agent_role_arn" {
  description = "ARN of Jenkins agent IAM role for ECR push (annotate ServiceAccount: eks.amazonaws.com/role-arn)"
  value       = aws_iam_role.jenkins_agent.arn
}

output "jenkins_agent_role_name" {
  description = "Name of Jenkins agent IAM role"
  value       = aws_iam_role.jenkins_agent.name
}

output "argocd_role_arn" {
  description = "ARN of ArgoCD IAM role for Secrets Manager (annotate ServiceAccount: eks.amazonaws.com/role-arn)"
  value       = aws_iam_role.argocd.arn
}

output "argocd_role_name" {
  description = "Name of ArgoCD IAM role"
  value       = aws_iam_role.argocd.name
}
