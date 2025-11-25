variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version to use for the EKS cluster"
  type        = string
  default     = "1.34"
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "private_subnet_ids" {
  description = "IDs of the private subnets"
  type        = list(string)
}

variable "ami_type" {
  description = "Type of AMI to use for EKS nodes"
  type        = string
}

variable "instance_types" {
  description = "Instance types to use for EKS nodes"
  type        = list(string)
}

variable "min_size" {
  description = "Minimum number of EKS nodes"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of EKS nodes"
  type        = number
  default     = 3
}

variable "desired_size" {
  description = "Desired number of EKS nodes"
  type        = number
  default     = 2
}

