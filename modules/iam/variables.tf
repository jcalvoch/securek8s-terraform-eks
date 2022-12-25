variable "user_name" {
  type        = string
  description = "Developer username"
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