variable "function_name" {
  type        = string
  description = "Name of the lambda"
}

variable "image_uri" {
  type        = string
  description = "ECR Image to use for the lambda"
}

variable "timeout" {
  type        = number
  default     = 10
  description = "The lambda function timeout (in seconds)"
}

variable "memory_size" {
  type        = number
  default     = 128
  description = "The memory to be provided for the lambda (in megabytes)"
}

variable "policy_arns" {
  type        = list(string)
  default     = []
  description = "Additional policy ARNs to attach to the role"
}

variable "policy_json" {
  type        = string
  default     = <<EOF
{
  "Version": "2012-10-17",
  "Statement": []
}
EOF
  description = "Additional policy json to attach"
}

variable "security_group_ids" {
  type        = list(string)
  description = "List of security group IDs to attach to lambda"
  default     = []
}

variable "subnet_ids" {
  type        = list(string)
  description = "List of subnet IDs to attach to lambda"
  default     = []
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags to add to the lambda"
}

variable "environment_variables" {
  type        = map(string)
  default     = {}
  description = "Environment variables to add to the lambda"
}

variable "log_retention_in_days" {
  type        = number
  default     = 14
  description = "Number of days to retail lambda logs"
}

variable "iam_role_arn" {
  type        = string
  default     = ""
  description = "IAM Role to use for the lambda. (Created if not provided)"
}

variable "iam_role_name_prefix" {
  type        = string
  default     = ""
  description = "Name prefix to be used when creating an IAM Role to use for the lambda."
}

variable "provisioned_concurrent_executions" {
  type        = number
  default     = 0
  description = "Amount of provisioned capacity to allocate"
}

#
# Lambda Autoscaling
#
variable "autoscaling_start_schedule" {
  type    = string
  default = ""
}

variable "autoscaling_end_schedule" {
  type    = string
  default = ""
}

variable "autoscaling_min_capacity" {
  type    = number
  default = 0
}

variable "autoscaling_max_capacity" {
  type    = number
  default = 0
}
