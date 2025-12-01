# Outputs for Secret Manager Module

output "secret_arns" {
  description = "Map of secret names to ARNs for ExternalSecret resources"
  value = {
    for name, secret in aws_secretsmanager_secret.secrets : name => secret.arn
  }
}

output "secret_names" {
  description = "List of all secret names created"
  value       = keys(aws_secretsmanager_secret.secrets)
}

output "manual_injection_commands" {
  description = "AWS CLI commands to manually inject secret values (run these after terraform apply)"
  value       = <<-EOT
    # ========================================
    # Manual Secret Injection Commands
    # ========================================

    # 1. Inject Jenkins admin password
    aws secretsmanager put-secret-value \
      --secret-id /internal-cluster/jenkins/admin-password \
      --secret-string "$(openssl rand -base64 24)"

    # 2. Inject Jenkins GitHub token
    # IMPORTANT: Replace with your actual GitHub Personal Access Token
    aws secretsmanager put-secret-value \
      --secret-id /internal-cluster/jenkins/github-token \
      --secret-string "ghp_YOUR_GITHUB_TOKEN_HERE"

    # 3. Inject Grafana admin password
    aws secretsmanager put-secret-value \
      --secret-id /internal-cluster/grafana/admin-password \
      --secret-string "$(openssl rand -base64 24)"

    # 4. Inject n8n admin password
    aws secretsmanager put-secret-value \
      --secret-id /internal-cluster/n8n/admin-password \
      --secret-string "$(openssl rand -base64 24)"

    # Verify Secrets Created
    aws secretsmanager list-secrets \
      --query 'SecretList[?starts_with(Name, `/internal-cluster`)].{Name:Name, ARN:ARN}' \
      --output table

    # Test Secret Retrieval
    aws secretsmanager get-secret-value \
      --secret-id /internal-cluster/jenkins/admin-password \
      --query SecretString \
      --output text
  EOT
}
