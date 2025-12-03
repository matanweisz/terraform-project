# Environment Orchestrator Configuration
# Copy this to terraform.tfvars and customize

project_name = "weather-app"
aws_region   = "eu-central-1"
aws_profile  = "full-project-user"

# Toggle which environments to provision
# Set to true to provision, false to skip
provision_dev  = true
provision_stg  = true
provision_prod = false

# Dev Environment Configuration
dev_cluster_name                = "dev-eks-cluster"
dev_kubernetes_version          = "1.34"
dev_instance_types              = ["t3.medium"]
dev_min_size                    = 1
dev_max_size                    = 2
dev_desired_size                = 1
dev_create_cloudwatch_log_group = false

# Staging Environment Configuration
stg_cluster_name                = "stg-eks-cluster"
stg_kubernetes_version          = "1.34"
stg_instance_types              = ["t3.medium"]
stg_min_size                    = 1
stg_max_size                    = 3
stg_desired_size                = 1
stg_create_cloudwatch_log_group = false

# Production Environment Configuration
prod_cluster_name                = "prod-eks-cluster"
prod_kubernetes_version          = "1.34"
prod_instance_types              = ["t3.large"]
prod_min_size                    = 2
prod_max_size                    = 5
prod_desired_size                = 3
prod_create_cloudwatch_log_group = false
