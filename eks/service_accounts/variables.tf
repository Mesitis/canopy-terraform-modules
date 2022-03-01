variable "name" {
  description = "Name of the environment"
  type        = string
}

variable "cluster_name" {
  description = "Name of the cluster"
  type        = string
}

variable "role_name_suffix" {
  description = "Suffix to add to the role names"
  type        = string
  default     = ""
}

variable "role_name_prefix" {
  description = "Prefix to add to the role names"
  type        = string
  default     = ""
}

variable "service_accounts" {
  description = "Service accounts to create"
  type = set(object({
    name                     = string
    namespace                = string
    attach_policy_arns       = set(string)
    with_k8s_service_account = bool
    rw_buckets               = set(string)
    ro_buckets               = set(string)
    inline_policies = set(object({
      name_prefix = string
      statements = set(object({
        Resource = set(string)
        Action   = set(string)
        Effect   = string
      }))
    }))
  }))
  default = []
}
