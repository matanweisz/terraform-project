variable "environment" {
  description = "Environment name (e.g., prod, dev, staging)"
  type        = string
}

variable "source_cluster_security_group_id" {
  description = "Security group ID of the source cluster (internal cluster) - kept for backward compatibility"
  type        = string
}

variable "source_node_security_group_id" {
  description = "Security group ID of the source cluster nodes (where ArgoCD pods run)"
  type        = string
}

variable "target_cluster_security_group_id" {
  description = "Security group ID of the target cluster (Terraform-managed) - kept for backward compatibility"
  type        = string
}

variable "target_cluster_primary_security_group_id" {
  description = "EKS-managed security group ID that controls access to the Kubernetes API endpoint"
  type        = string
}

variable "target_node_security_group_id" {
  description = "Security group ID of the target cluster (this environment's cluster) nodes"
  type        = string
}
