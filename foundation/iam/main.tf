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
      values   = ["system:serviceaccount:kube-system:alb-controller-sa"]
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


# Jenkins IAM Role (ECR Push)
# This role is used by both the Jenkins controller and dynamic agent pods
data "aws_iam_policy_document" "jenkins_ecr_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.oidc_provider}:sub"
      # Allow both jenkins service account and dynamically created agent pods
      values   = [
        "system:serviceaccount:jenkins:jenkins",
        "system:serviceaccount:jenkins:default"
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.oidc_provider}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "jenkins_ecr" {
  name               = "${var.project_name}-jenkins-ecr"
  assume_role_policy = data.aws_iam_policy_document.jenkins_ecr_assume_role.json

  tags = {
    Name      = "${var.project_name}-jenkins-ecr"
    Cluster   = var.cluster_name
    ManagedBy = "terraform"
  }
}

resource "aws_iam_policy" "jenkins_ecr" {
  name        = "${var.project_name}-jenkins-ecr-policy"
  description = "Allows Jenkins agents to push images to ECR"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ecr:GetAuthorizationToken"]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
        Resource = var.ecr_repository_arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "jenkins_ecr" {
  role       = aws_iam_role.jenkins_ecr.name
  policy_arn = aws_iam_policy.jenkins_ecr.arn
}


# ArgoCD IAM Role (for ArgoCD to read from the Secrets Manager)
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
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:argocd/*"
      }
      # Note: Cross-cluster AssumeRole will be added in Phase 4 when production cluster is created
    ]
  })
}

resource "aws_iam_role_policy_attachment" "argocd_secrets" {
  role       = aws_iam_role.argocd.name
  policy_arn = aws_iam_policy.argocd_secrets.arn
}

# ArgoCD EKS Access Policy (for cross-cluster management)
resource "aws_iam_policy" "argocd_eks_access" {
  name        = "${var.project_name}-argocd-eks-access-policy"
  description = "Allows ArgoCD to describe EKS clusters and manage cross-cluster deployments"
  policy      = file("${path.module}/policies/argocd-eks-access.json")

  tags = {
    Name      = "${var.project_name}-argocd-eks-access-policy"
    ManagedBy = "terraform"
  }
}

resource "aws_iam_role_policy_attachment" "argocd_eks_access" {
  role       = aws_iam_role.argocd.name
  policy_arn = aws_iam_policy.argocd_eks_access.arn
}


# External Secrets Operator IAM Role (reads the secrets from AWS Secrets Manager)
data "aws_iam_policy_document" "external_secrets_assume_role" {
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
        "system:serviceaccount:external-secrets:external-secrets",
        "system:serviceaccount:external-secrets:external-secrets-webhook",
        "system:serviceaccount:external-secrets:external-secrets-cert-controller"
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.oidc_provider}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "external_secrets" {
  name               = "${var.project_name}-external-secrets"
  assume_role_policy = data.aws_iam_policy_document.external_secrets_assume_role.json

  tags = {
    Name      = "${var.project_name}-external-secrets"
    Cluster   = var.cluster_name
    ManagedBy = "terraform"
  }
}

resource "aws_iam_policy" "external_secrets" {
  name        = "${var.project_name}-external-secrets-policy"
  description = "Allows External Secrets Operator to read secrets from Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadInternalClusterSecrets"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:/internal-cluster/*"
      },
      {
        Sid      = "ListSecretsForDebugging"
        Effect   = "Allow"
        Action   = ["secretsmanager:ListSecrets"]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "external_secrets" {
  role       = aws_iam_role.external_secrets.name
  policy_arn = aws_iam_policy.external_secrets.arn
}


# EBS CSI Driver IAM Role
data "aws_iam_policy_document" "ebs_csi_driver_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.oidc_provider}:sub"
      values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.oidc_provider}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ebs_csi_driver" {
  name               = "${var.project_name}-ebs-csi-driver"
  assume_role_policy = data.aws_iam_policy_document.ebs_csi_driver_assume_role.json
}

resource "aws_iam_role_policy_attachment" "ebs_csi_driver" {
  role       = aws_iam_role.ebs_csi_driver.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}
