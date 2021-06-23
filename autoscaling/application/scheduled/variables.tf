variable "start_schedule" {
  type = string
}

variable "end_schedule" {
  type = string
}

variable "min_capacity" {
  type = number
}

variable "max_capacity" {
  type = number
}

variable "resource_id" {
  type = string
}

variable "scalable_dimension" {
  type = string
}

variable "service_namespace" {
  type = string
}

variable "scheduled_action_name_prefix" {
  type    = string
  default = ""
}

