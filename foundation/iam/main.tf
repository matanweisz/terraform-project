# IAM Roles for Service Accounts (IRSA)

data "aws_caller_identity" "current" {}

# ALB Ingress Controller IAM Role
data "aws_iam_policy_document" "alb_controller_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.oidc_provider}:sub"
      values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.oidc_provider}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "alb_controller" {
  name               = "${var.project_name}-alb-controller"
  assume_role_policy = data.aws_iam_policy_document.alb_controller_assume_role.json

  tags = {
    Name      = "${var.project_name}-alb-controller"
    Cluster   = var.cluster_name
    ManagedBy = "terraform"
  }
}

resource "aws_iam_policy" "alb_controller" {
  name        = "${var.project_name}-alb-controller-policy"
  description = "IAM policy for AWS Load Balancer Controller"
  policy      = file("${path.module}/policies/alb-controller.json")
}

resource "aws_iam_role_policy_attachment" "alb_controller" {
  role       = aws_iam_role.alb_controller.name
  policy_arn = aws_iam_policy.alb_controller.arn
}

# Jenkins Agent IAM Role (ECR Push)
data "aws_iam_policy_document" "jenkins_agent_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.oidc_provider}:sub"
      values   = ["system:serviceaccount:jenkins:jenkins-agent"]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.oidc_provider}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "jenkins_agent" {
  name               = "${var.project_name}-jenkins-agent"
  assume_role_policy = data.aws_iam_policy_document.jenkins_agent_assume_role.json

  tags = {
    Name      = "${var.project_name}-jenkins-agent"
    Cluster   = var.cluster_name
    ManagedBy = "terraform"
  }
}

resource "aws_iam_policy" "jenkins_ecr" {
  name        = "${var.project_name}-jenkins-ecr-policy"
  description = "Allows Jenkins agents to push images to ECR"
  policy      = file("${path.module}/policies/jenkins-ecr-push.json")
}

resource "aws_iam_role_policy_attachment" "jenkins_agent" {
  role       = aws_iam_role.jenkins_agent.name
  policy_arn = aws_iam_policy.jenkins_ecr.arn
}

# ArgoCD IAM Role (Secrets Manager)
data "aws_iam_policy_document" "argocd_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.oidc_provider}:sub"
      values = [
        "system:serviceaccount:argocd:argocd-server",
        "system:serviceaccount:argocd:argocd-application-controller",
        "system:serviceaccount:argocd:argocd-repo-server"
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.oidc_provider}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "argocd" {
  name               = "${var.project_name}-argocd"
  assume_role_policy = data.aws_iam_policy_document.argocd_assume_role.json

  tags = {
    Name      = "${var.project_name}-argocd"
    Cluster   = var.cluster_name
    ManagedBy = "terraform"
  }
}

resource "aws_iam_policy" "argocd_secrets" {
  name        = "${var.project_name}-argocd-secrets-policy"
  description = "Allows ArgoCD to read secrets from Secrets Manager"
  policy      = file("${path.module}/policies/argocd-secrets-manager.json")
}

resource "aws_iam_role_policy_attachment" "argocd" {
  role       = aws_iam_role.argocd.name
  policy_arn = aws_iam_policy.argocd_secrets.arn
}
