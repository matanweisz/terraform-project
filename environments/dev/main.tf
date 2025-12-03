# Development EKS Cluster
module "eks_cluster" {
  source = "../modules/eks-cluster"

  cluster_name       = var.cluster_name
  kubernetes_version = var.kubernetes_version
  vpc_id             = local.vpc_id
  private_subnet_ids = local.private_subnet_ids

  ami_type       = var.ami_type
  instance_types = var.instance_types
  min_size       = var.min_size
  max_size       = var.max_size
  desired_size   = var.desired_size
  create_cloudwatch_log_group = var.create_cloudwatch_log_group
}

# ECR Repository for Dev Environment
module "ecr" {
  source = "../modules/ecr"

  repository_name      = "${var.project_name}-${var.environment}"
  environment          = var.environment
  image_tag_mutability = var.ecr_image_tag_mutability
  scan_on_push         = var.ecr_scan_on_push
  max_image_count      = var.ecr_max_image_count
}

# IAM Roles for Service Accounts (IRSA)
module "irsa_roles" {
  source = "../modules/irsa-roles"

  environment       = var.environment
  project_name      = var.project_name
  aws_region        = var.aws_region
  oidc_provider_arn = module.eks_cluster.oidc_provider_arn
  oidc_provider     = module.eks_cluster.oidc_provider
}

# Cross-cluster access for ArgoCD from internal cluster
module "cluster_access" {
  source = "../modules/cluster-access"

  environment                            = var.environment
  source_cluster_security_group_id       = local.internal_cluster_security_group_id
  source_node_security_group_id          = local.internal_cluster_node_security_group_id
  target_cluster_security_group_id       = module.eks_cluster.cluster_security_group_id
  target_cluster_primary_security_group_id = module.eks_cluster.cluster_primary_security_group_id
  target_node_security_group_id          = module.eks_cluster.node_security_group_id
}
