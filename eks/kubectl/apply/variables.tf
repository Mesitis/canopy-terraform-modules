variable "cluster_name" {
  type        = string
  description = "Name of the cluster"
}

variable "manifests" {
  type        = set(string)
  description = "the YAML manifests to apply"
}

variable "validate" {
  type        = bool
  default     = true
  description = "should the manifests be validated"
}