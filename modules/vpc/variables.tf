variable "region" {
  type        = string
  default     = "us-east-1"
  description = "Default US region to use"
}

variable "environment" {
  type        = string
  default     = "stage"
  description = "App environment"
}

variable "project_name" {
  type        = string
  default     = "eks-test"
  description = "Project name"
}

variable "profile" {
  type        = string
  default     = "default"
  description = "AWS CLI profile"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC subnet"
}
