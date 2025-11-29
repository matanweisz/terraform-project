variable "environment" {
  description = "Environment name (e.g., prod, dev, staging)"
  type        = string
}

variable "source_cluster_security_group_id" {
  description = "Security group ID of the source cluster (internal cluster) that needs access"
  type        = string
}

variable "target_cluster_security_group_id" {
  description = "Security group ID of the target cluster (this environment's cluster) control plane"
  type        = string
}

variable "target_node_security_group_id" {
  description = "Security group ID of the target cluster (this environment's cluster) nodes"
  type        = string
}
