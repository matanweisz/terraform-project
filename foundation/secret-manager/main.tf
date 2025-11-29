# AWS Secrets Manager Module

# Creates secret placeholders (values injected manually via AWS CLI)
# Secret naming convention: /internal-cluster/<application>/<secret-name>

locals {
  secrets_config = {
    "/internal-cluster/jenkins/admin-password" = {
      description = "Jenkins admin user password"
      application = "jenkins"
    }
    "/internal-cluster/jenkins/github-token" = {
      description = "GitHub Personal Access Token for Jenkins SCM"
      application = "jenkins"
    }
    "/internal-cluster/grafana/admin-password" = {
      description = "Grafana admin user password"
      application = "grafana"
    }
    "/internal-cluster/n8n/admin-password" = {
      description = "n8n admin user password for basic authentication"
      application = "n8n"
    }
  }
}

resource "aws_secretsmanager_secret" "secrets" {
  for_each = local.secrets_config

  name        = each.key
  description = each.value.description

  recovery_window_in_days = 0 # Immediate deletion (allows immediate recreation)

  tags = {
    Name        = each.key
    Application = each.value.application
    Cluster     = var.cluster_name
    ManagedBy   = "terraform"
  }
}
