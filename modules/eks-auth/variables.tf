variable "nodegroup_role" {
  type = string
  description = "IAM role of the kubernetes worker nodes"
}

variable "account_id" {
  type = string
  description = "Account ID"
}

variable "user_name" {
  type        = string
  description = "Developer username"
}
