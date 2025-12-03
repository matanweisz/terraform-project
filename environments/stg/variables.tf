# Global Variables
variable "project_name" {
  description = "Name of the project (used for resource naming)"
  type        = string
  default     = "weather-app"
}

variable "environment" {
  description = "Environment name (prod, dev, staging)"
  type        = string
  default     = "staging"

  validation {
    condition     = contains(["prod", "dev", "staging"], var.environment)
    error_message = "Environment must be one of: prod, dev, staging"
  }
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

# EKS Cluster Variables
variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.34"
}

variable "create_cloudwatch_log_group" {
  description = "Controls if a CloudWatch log group is created for the cluster"
  type        = bool
  default     = false
}

variable "ami_type" {
  description = "AMI type for EKS nodes (must match instance architecture)"
  type        = string
  default     = "AL2023_x86_64_STANDARD"
}

variable "instance_types" {
  description = "List of instance types for EKS nodes"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "min_size" {
  description = "Minimum number of EKS nodes"
  type        = number
  default     = 1

  validation {
    condition     = var.min_size >= 1
    error_message = "Minimum size must be at least 1"
  }
}

variable "max_size" {
  description = "Maximum number of EKS nodes"
  type        = number
  default     = 3

  validation {
    condition     = var.max_size >= 1
    error_message = "Maximum size must be at least 1"
  }
}

variable "desired_size" {
  description = "Desired number of EKS nodes"
  type        = number
  default     = 1
}

# ECR Variables
variable "ecr_image_tag_mutability" {
  description = "Image tag mutability setting for ECR (MUTABLE or IMMUTABLE)"
  type        = string
  default     = "MUTABLE"
}

variable "ecr_scan_on_push" {
  description = "Enable vulnerability scanning on image push"
  type        = bool
  default     = true
}

variable "ecr_max_image_count" {
  description = "Maximum number of images to keep in ECR repository"
  type        = number
  default     = 30
}
