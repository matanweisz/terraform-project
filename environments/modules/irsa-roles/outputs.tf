output "alb_controller_role_arn" {
  description = "ARN of the ALB Ingress Controller IAM role (use in ServiceAccount annotation)"
  value       = aws_iam_role.alb_controller.arn
}

output "alb_controller_role_name" {
  description = "Name of the ALB Ingress Controller IAM role"
  value       = aws_iam_role.alb_controller.name
}
