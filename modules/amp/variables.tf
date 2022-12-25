variable "environment" {
  type        = string
  default     = "dev"
  description = "App environment"
}

variable "project_name" {
  type        = string
  default     = "eks-test"
  description = "Project name"
}

variable "oidc_provider_url" {
  type = string
  description = "Kubernetes cluster OIDC provider"
}

variable "account_id" {
  type = string
  description = "Account ID"
}