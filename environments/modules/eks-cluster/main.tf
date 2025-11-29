module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = var.cluster_name
  kubernetes_version = var.kubernetes_version

  # Core EKS addons for application workloads
  addons = {
    coredns = {
      most_recent = true
    }
    eks-pod-identity-agent = {
      most_recent    = true
      before_compute = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent    = true
      before_compute = true
    }
  }

  # Public endpoint for ALB and external access
  endpoint_public_access                   = true
  enable_cluster_creator_admin_permissions = true

  # Enable IRSA for service account authentication
  enable_irsa = true

  # Networking
  vpc_id                   = var.vpc_id
  subnet_ids               = var.private_subnet_ids
  control_plane_subnet_ids = var.private_subnet_ids

  # Node groups
  eks_managed_node_groups = {
    main = {
      ami_type       = var.ami_type
      instance_types = var.instance_types

      min_size     = var.min_size
      max_size     = var.max_size
      desired_size = var.desired_size

      # Tags for node identification
      tags = merge(
        var.tags,
        {
          Name = "${var.cluster_name}-node"
        }
      )
    }
  }

  # Cluster tags
  tags = merge(
    var.tags,
    {
      Name = var.cluster_name
    }
  )
}
