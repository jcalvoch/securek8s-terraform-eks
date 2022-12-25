variable "region" {
  type        = string
  default     = "us-east-1"
  description = "Default US region to use"
}

variable "environment" {
  type        = string
  description = "App environment"
}

variable "project_name" {
  type        = string
  description = "Project name"
}

variable "profile" {
  type        = string
  default     = "default"
  description = "AWS CLI profile"
}


variable "security_group_id" {
  type = string
  description = "Security Group that will be used for K8s EKS cluster"
}

variable "subnet_ids" {
  type = list
  description = "Subnet list to be utilized on the cluster"
}

variable "account_id" {
  type = string
  description = "Account ID"
}
