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

# VPC Variables
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.20.0/24", "10.0.30.0/24"]
}

variable "azs" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]
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

# ECR Variables
variable "ecr_repository_name" {
  description = "Name of the ECR repository for container images"
  type        = string
  default     = "weather-app"
}

variable "ecr_image_tag_mutability" {
  description = "Image tag mutability setting for ECR (MUTABLE allows overwriting tags)"
  type        = string
  default     = "MUTABLE"
}

variable "ecr_scan_on_push" {
  description = "Enable automatic vulnerability scanning when images are pushed"
  type        = bool
  default     = true
}

variable "ecr_max_image_count" {
  description = "Maximum number of images to retain in ECR (older images auto-deleted)"
  type        = number
  default     = 30
}
