# Security group rules to allow cross-cluster communication
# Allows ArgoCD in internal-cluster to manage applications in this environment cluster

# Allow internal cluster nodes (where ArgoCD pods run) to access prod cluster API
resource "aws_security_group_rule" "allow_internal_nodes_to_control_plane" {
  description              = "Allow internal cluster nodes to communicate with ${var.environment} cluster API server"
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = var.target_cluster_primary_security_group_id
  source_security_group_id = var.source_node_security_group_id
}

resource "aws_security_group_rule" "allow_internal_cluster_to_nodes" {
  description              = "Allow internal cluster to communicate with ${var.environment} cluster nodes"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = var.target_node_security_group_id
  source_security_group_id = var.source_cluster_security_group_id
}

# Allow response traffic back to internal cluster
resource "aws_security_group_rule" "allow_response_to_internal_cluster" {
  description              = "Allow ${var.environment} cluster to respond to internal cluster"
  type                     = "egress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "-1"
  security_group_id        = var.target_cluster_security_group_id
  source_security_group_id = var.source_cluster_security_group_id
}
