# Global Variables
variable "project_name" {
  description = "Name of the terraform project (used for resource naming)"
  type        = string
  default     = "terraform-project"
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
  description = "Name of the internal EKS cluster"
  type        = string
  default     = "internal-cluster"
}

variable "kubernetes_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.34"
}

variable "ami_type" {
  description = "AMI type for EKS nodes (must match instance architecture)"
  type        = string
}

variable "instance_types" {
  description = "List of instance types for EKS nodes"
  type        = list(string)
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
  default     = 2

  validation {
    condition     = var.desired_size >= var.min_size && var.desired_size <= var.max_size
    error_message = "Desired size must be between min_size and max_size"
  }
}

variuable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "private_subnet_ids" {
  description = "IDs of the private subnets"
  type        = list(string)
}
