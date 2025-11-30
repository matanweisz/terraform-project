module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = var.cluster_name
  kubernetes_version = var.kubernetes_version

  addons = {
    coredns = {}
    eks-pod-identity-agent = {
      before_compute = true
    }
    kube-proxy = {}
    vpc-cni = {
      before_compute = true
    }
  }

  endpoint_public_access                   = true
  enable_cluster_creator_admin_permissions = true

  enable_irsa                 = true
  create_cloudwatch_log_group = var.create_cloudwatch_log_group

  vpc_id                   = var.vpc_id
  subnet_ids               = var.private_subnet_ids
  control_plane_subnet_ids = var.private_subnet_ids

  eks_managed_node_groups = {
    internal = {
      ami_type       = var.ami_type
      instance_types = var.instance_types

      min_size     = var.min_size
      max_size     = var.max_size
      desired_size = var.desired_size
    }
  }
}
