variable "function_name" {
  type = string
  description = "Name of the lambda"
}

variable "image_uri" {
  type = string
  description = "ECR Image to use for the lambda"
}

variable "timeout" {
  type = number
  default = 10
  description = "The lambda function timeout (in seconds)"
}

variable "memory_size" {
  type = number
  default = 128
  description = "The memory to be provided for the lambda (in megabytes)"
}

variable "policy_json" {
  type = string
  default = <<EOF
{
  "Version": "2012-10-17",
  "Statement": []
}
EOF
  description = "Additional policy json to attach"
}

variable "security_group_ids" {
  type = list(string)
  description = "List of security group IDs to attach to lambda"
}

variable "subnet_ids" {
  type = list(string)
  description = "List of subnet IDs to attach to lambda"
}

variable "tags" {
  type = map(string)
  default = {}
  description = "Tags to add to the lambda"
}

variable "environment_variables" {
  type = map(string)
  default = {}
  description = "Environment variables to add to the lambda"
}
