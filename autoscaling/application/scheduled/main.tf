resource "aws_appautoscaling_target" "this" {
  max_capacity       = var.max_capacity
  min_capacity       = var.min_capacity
  resource_id        = var.resource_id
  scalable_dimension = var.scalable_dimension
  service_namespace  = var.service_namespace
}

locals {
  scheduled_action_name_prefix = var.scheduled_action_name_prefix == "" ? replace(aws_appautoscaling_target.this.resource_id, "/", "-") : var.scheduled_action_name_prefix
}

resource "aws_appautoscaling_scheduled_action" "this_start" {
  name               = "${local.scheduled_action_name_prefix}-start"
  service_namespace  = aws_appautoscaling_target.this.service_namespace
  resource_id        = aws_appautoscaling_target.this.resource_id
  scalable_dimension = aws_appautoscaling_target.this.scalable_dimension
  schedule           = var.start_schedule

  scalable_target_action {
    min_capacity = var.min_capacity
    max_capacity = var.max_capacity
  }
}

resource "aws_appautoscaling_scheduled_action" "this_end" {
  name               = "${local.scheduled_action_name_prefix}-end"
  service_namespace  = aws_appautoscaling_target.this.service_namespace
  resource_id        = aws_appautoscaling_target.this.resource_id
  scalable_dimension = aws_appautoscaling_target.this.scalable_dimension
  schedule           = var.end_schedule

  scalable_target_action {
    min_capacity = 0
    max_capacity = 0
  }
}
