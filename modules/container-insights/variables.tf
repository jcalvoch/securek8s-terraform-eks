variable "region" {
  type        = string
  default     = "us-east-1"
  description = "Default US region to use"
}

variable "cluster_name" {
  type        = string
  description = "Kubernetes cluster name"

}

variable "environment" {
  type        = string
  default     = "stage"
  description = "App environment"
}

variable "project_name" {
  type        = string
  default     = "test"
  description = "Project name"
}