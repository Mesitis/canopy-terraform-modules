locals {
  has_autoscaling = var.autoscaling_start_schedule != "" && var.autoscaling_end_schedule != "" && var.autoscaling_max_capacity > 0
}

resource "aws_iam_role" "iam_for_lambda" {
  count = var.iam_role_arn == "" ? 1 : 0
  name  = "${var.function_name}Role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = var.log_retention_in_days
}

resource "aws_iam_role_policy_attachment" "eni_policy" {
  count      = var.iam_role_arn == "" ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaENIManagementAccess"
  role       = aws_iam_role.iam_for_lambda[0].id
}

resource "aws_iam_role_policy_attachment" "basic_policy" {
  count      = var.iam_role_arn == "" ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.iam_for_lambda[0].id
}

resource "aws_iam_role_policy_attachment" "extra_policies" {
  for_each   = toset(var.iam_role_arn == "" ? var.policy_arns : [])
  policy_arn = each.value
  role       = aws_iam_role.iam_for_lambda[0].id
}

resource "aws_iam_role_policy" "policy" {
  count  = var.iam_role_arn == "" ? 1 : 0
  policy = var.policy_json
  role   = aws_iam_role.iam_for_lambda[0].id
}

//noinspection MissingProperty
resource "aws_lambda_function" "lambda" {
  function_name    = var.function_name
  package_type     = "Image"
  image_uri        = var.image_uri
  role             = var.iam_role_arn == "" ? aws_iam_role.iam_for_lambda[0].arn : var.iam_role_arn
  source_code_hash = base64sha256(timestamp())
  timeout          = var.timeout
  memory_size      = var.memory_size
  tags             = merge(var.tags, { Name = var.function_name })
  publish          = true

  environment {
    variables = var.environment_variables
  }

  dynamic "vpc_config" {
    for_each = length(var.subnet_ids) > 0 ? ["true"] : []
    content {
      security_group_ids = var.security_group_ids
      subnet_ids         = var.subnet_ids
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.basic_policy,
    aws_iam_role_policy_attachment.eni_policy,
    aws_iam_role_policy.policy,
    aws_cloudwatch_log_group.lambda,
  ]
}

resource "aws_lambda_alias" "latest" {
  function_name    = aws_lambda_function.lambda.function_name
  function_version = aws_lambda_function.lambda.version
  name             = "latest"
  depends_on       = [aws_lambda_function.lambda]
}

resource "aws_lambda_provisioned_concurrency_config" "lambda" {
  count                             = var.provisioned_concurrent_executions > 0 ? 1 : 0
  function_name                     = aws_lambda_function.lambda.arn
  provisioned_concurrent_executions = var.provisioned_concurrent_executions
  qualifier                         = aws_lambda_alias.latest.name
  depends_on                        = [aws_lambda_function.lambda, aws_lambda_alias.latest]
}

module "autoscaling" {
  count                        = local.has_autoscaling ? 1 : 0
  source                       = "github.com/Mesitis/canopy-terraform-modules//autoscaling/application/scheduled"
  max_capacity                 = var.autoscaling_max_capacity
  min_capacity                 = var.autoscaling_min_capacity
  resource_id                  = "function:${aws_lambda_function.lambda.function_name}:${aws_lambda_alias.latest.name}"
  scheduled_action_name_prefix = aws_lambda_function.lambda.function_name
  scalable_dimension           = "lambda:function:ProvisionedConcurrency"
  service_namespace            = "lambda"
  start_schedule               = var.autoscaling_start_schedule
  end_schedule                 = var.autoscaling_end_schedule
  depends_on                   = [aws_lambda_alias.latest]
}