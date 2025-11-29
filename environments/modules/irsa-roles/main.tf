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
  name               = "${var.environment}-${var.project_name}-alb-controller"
  assume_role_policy = data.aws_iam_policy_document.alb_controller_assume_role.json

  tags = merge(
    var.tags,
    {
      Name      = "${var.environment}-${var.project_name}-alb-controller"
      Component = "alb-controller"
    }
  )
}

resource "aws_iam_policy" "alb_controller" {
  name        = "${var.environment}-${var.project_name}-alb-controller-policy"
  description = "IAM policy for AWS Load Balancer Controller in ${var.environment}"
  policy      = file("${path.module}/policies/alb-controller.json")

  tags = merge(
    var.tags,
    {
      Name      = "${var.environment}-${var.project_name}-alb-controller-policy"
      Component = "alb-controller"
    }
  )
}

resource "aws_iam_role_policy_attachment" "alb_controller" {
  role       = aws_iam_role.alb_controller.name
  policy_arn = aws_iam_policy.alb_controller.arn
}
