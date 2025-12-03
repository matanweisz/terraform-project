# Local values for environment management
locals {
  # List of enabled environments for backend synchronization
  enabled_environments = compact([
    var.provision_dev ? "dev" : "",
    var.provision_stg ? "stg" : "",
    var.provision_prod ? "prod" : "",
  ])

  # Add the orchestrator bucket to the list
  all_buckets = concat(["environments"], local.enabled_environments)
}

# Output for backend project to consume
output "enabled_environments_for_backend" {
  description = "List of enabled environments - use this to sync with backend project"
  value       = local.enabled_environments
}
