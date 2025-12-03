variable "project_name" {
  description = "Name of the project (used for resource naming)"
  type        = string
  default     = "weather-app"
}

variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "eu-central-1"
}

variable "aws_profile" {
  description = "AWS CLI profile to use for authentication"
  type        = string
  default     = "default"
}

# Environment Provisioning Toggles
variable "provision_dev" {
  description = "Whether to provision the dev environment"
  type        = bool
  default     = false
}

variable "provision_stg" {
  description = "Whether to provision the staging environment"
  type        = bool
  default     = false
}

variable "provision_prod" {
  description = "Whether to provision the production environment"
  type        = bool
  default     = false
}

# Dev Environment Configuration
variable "dev_cluster_name" {
  description = "Name of the dev EKS cluster"
  type        = string
  default     = "dev-eks-cluster"
}

variable "dev_kubernetes_version" {
  description = "Kubernetes version for dev cluster"
  type        = string
  default     = "1.34"
}

variable "dev_instance_types" {
  description = "Instance types for dev nodes"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "dev_min_size" {
  description = "Minimum nodes for dev"
  type        = number
  default     = 1
}

variable "dev_max_size" {
  description = "Maximum nodes for dev"
  type        = number
  default     = 2
}

variable "dev_desired_size" {
  description = "Desired nodes for dev"
  type        = number
  default     = 1
}

variable "dev_create_cloudwatch_log_group" {
  description = "Create CloudWatch log group for dev cluster"
  type        = bool
  default     = false
}

# Staging Environment Configuration
variable "stg_cluster_name" {
  description = "Name of the staging EKS cluster"
  type        = string
  default     = "stg-eks-cluster"
}

variable "stg_kubernetes_version" {
  description = "Kubernetes version for staging cluster"
  type        = string
  default     = "1.34"
}

variable "stg_instance_types" {
  description = "Instance types for staging nodes"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "stg_min_size" {
  description = "Minimum nodes for staging"
  type        = number
  default     = 1
}

variable "stg_max_size" {
  description = "Maximum nodes for staging"
  type        = number
  default     = 3
}

variable "stg_desired_size" {
  description = "Desired nodes for staging"
  type        = number
  default     = 2
}

variable "stg_create_cloudwatch_log_group" {
  description = "Create CloudWatch log group for staging cluster"
  type        = bool
  default     = false
}

# Production Environment Configuration
variable "prod_cluster_name" {
  description = "Name of the production EKS cluster"
  type        = string
  default     = "prod-eks-cluster"
}

variable "prod_kubernetes_version" {
  description = "Kubernetes version for production cluster"
  type        = string
  default     = "1.34"
}

variable "prod_instance_types" {
  description = "Instance types for production nodes"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "prod_min_size" {
  description = "Minimum nodes for production"
  type        = number
  default     = 2
}

variable "prod_max_size" {
  description = "Maximum nodes for production"
  type        = number
  default     = 5
}

variable "prod_desired_size" {
  description = "Desired nodes for production"
  type        = number
  default     = 3
}

variable "prod_create_cloudwatch_log_group" {
  description = "Create CloudWatch log group for production cluster"
  type        = bool
  default     = false
}
