output "control_plane_ingress_rule_id" {
  description = "ID of the security group rule allowing internal cluster nodes to access control plane"
  value       = aws_security_group_rule.allow_internal_nodes_to_control_plane.id
}

output "node_ingress_rule_id" {
  description = "ID of the security group rule allowing access to nodes"
  value       = aws_security_group_rule.allow_internal_cluster_to_nodes.id
}

output "egress_rule_id" {
  description = "ID of the security group rule allowing response traffic"
  value       = aws_security_group_rule.allow_response_to_internal_cluster.id
}
