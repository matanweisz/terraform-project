# Remote state data source to retrieve foundation layer outputs
data "terraform_remote_state" "foundation" {
  backend = "s3"

  config = {
    bucket = "foundation-terraform-s3-remote-state"
    key    = "terraform.tfstate"
    region = "eu-central-1"
  }
}

# Local values for convenient access to foundation outputs
locals {
  # VPC and networking from foundation
  vpc_id             = data.terraform_remote_state.foundation.outputs.vpc_id
  vpc_cidr_block     = data.terraform_remote_state.foundation.outputs.vpc_cidr_block
  private_subnet_ids = data.terraform_remote_state.foundation.outputs.private_subnet_ids
  public_subnet_ids  = data.terraform_remote_state.foundation.outputs.public_subnet_ids

  # Internal cluster details for cross-cluster communication
  internal_cluster_endpoint               = data.terraform_remote_state.foundation.outputs.internal_cluster_endpoint
  internal_cluster_security_group_id      = data.terraform_remote_state.foundation.outputs.internal_cluster_security_group_id
  internal_cluster_node_security_group_id = data.terraform_remote_state.foundation.outputs.internal_cluster_node_security_group_id
  internal_cluster_oidc_provider_arn      = data.terraform_remote_state.foundation.outputs.internal_cluster_oidc_provider_arn

  # ECR repository from foundation
  ecr_repository_url = data.terraform_remote_state.foundation.outputs.ecr_repository_url
  ecr_repository_arn = data.terraform_remote_state.foundation.outputs.ecr_repository_arn

  # IAM role ARNs from foundation
  argocd_role_arn = data.terraform_remote_state.foundation.outputs.argocd_role_arn
}
