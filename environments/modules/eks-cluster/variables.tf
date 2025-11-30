variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.34"
}

variable "vpc_id" {
  description = "ID of the VPC where cluster will be created"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for EKS nodes and control plane"
  type        = list(string)
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

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "create_cloudwatch_log_group" {
  description = "Controls if a CloudWatch log group is created for the cluster"
  type        = bool
  default     = false
}
