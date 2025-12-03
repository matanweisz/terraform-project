# Summary of provisioned environments
output "provisioned_environments" {
  description = "List of provisioned environments"
  value = compact([
    var.provision_dev ? "dev" : "",
    var.provision_stg ? "stg" : "",
    var.provision_prod ? "prod" : "",
  ])
}

# Dev Environment Outputs
output "dev_cluster_endpoint" {
  description = "Dev cluster endpoint"
  value       = var.provision_dev ? module.dev[0].cluster_endpoint : "Not provisioned"
}

output "dev_cluster_name" {
  description = "Dev cluster name"
  value       = var.provision_dev ? module.dev[0].cluster_name : "Not provisioned"
}

# Staging Environment Outputs
output "stg_cluster_endpoint" {
  description = "Staging cluster endpoint"
  value       = var.provision_stg ? module.stg[0].cluster_endpoint : "Not provisioned"
}

output "stg_cluster_name" {
  description = "Staging cluster name"
  value       = var.provision_stg ? module.stg[0].cluster_name : "Not provisioned"
}

# Production Environment Outputs
output "prod_cluster_endpoint" {
  description = "Production cluster endpoint"
  value       = var.provision_prod ? module.prod[0].cluster_endpoint : "Not provisioned"
}

output "prod_cluster_name" {
  description = "Production cluster name"
  value       = var.provision_prod ? module.prod[0].cluster_name : "Not provisioned"
}
