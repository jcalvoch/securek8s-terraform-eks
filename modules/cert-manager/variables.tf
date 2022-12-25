variable "environment" {
  type        = string
  description = "App environment"
}

variable "project_name" {
  type        = string
  description = "Project name"
}

variable "route53_zoneid" {
  type = string
  description = "Required for Letsencrypt DNS01 validation"
}

variable "oidc_provider_url" {
  type = string
  description = "Kubernetes cluster OIDC provider"
}

variable "account_id" {
  type = string
  description = "Account ID"
}

variable "region" {
  type = string
  description = "AWS region"
}