variable "project_name" {
  description = "Name of the terraform project"
  type        = string
  default     = "terraform-project"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}
