variable "charts" {
  description = "The helm charts to deploy"
  type = list(object({
    enabled    = bool
    name       = string
    chart      = string
    repository = string
    version    = any
    namespace  = string
    values     = string
  }))
  default = []
}

variable "cluster_name" {
  description = "Name of the cluster"
}

variable "secrets" {
  description = "The secrets to create"
  type        = map(any)
  default     = {}
}

variable "yaml_resources" {
  description = "The yaml kubernetes resources to deploy"
  type        = set(string)
  default     = []
}

variable "overrides" {
  description = "The environment specific overrides for the chart values"
  type        = string
  default     = "{}"
}

variable "disabled" {
  description = "List of disabled workloads. Alternative to specifying enabled"
  type        = list(string)
  default     = []
}
