variable "region" {
  type        = string
  default     = "us-east-1"
  description = "Default US region to use"
}

variable "environment" {
  type        = string
  default     = "test"
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
  default     = "172.16.0.0/16"
  description = "VPC subnet"
}

variable "user_name" {
  type        = string
  default     = "app_user"
  description = "Developer username"
}

variable "route53_zoneid" {
  type = string
  description = "Required for Kubernetes Let's Encrypt cert-manager plugin"
}
