variable "region" {
  type        = string
  default     = "us-east-1"
  description = "Default US region to use"
}

variable "amp_rolearn" {
  type = string
  description = "ARN for service account IAM role created for Prometheus"
}


variable "amp_workspaceid" {
  type = string
  description = "ARN for service account IAM role created for Prometheus"
}
