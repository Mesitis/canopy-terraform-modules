variable "cluster_name" {
  type        = string
  description = "Name of the cluster"
}

variable "args" {
  type        = string
  description = "Arguments to pass to kubectl"
}

variable "destroy_args" {
  type    = string
  default = ""
}

variable "re_run" {
  type        = bool
  default     = false
  description = "Re-run the command every-time"
}