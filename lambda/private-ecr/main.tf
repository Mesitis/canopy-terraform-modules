resource "aws_iam_role" "iam_for_lambda" {
  name = "${var.function_name}Role"

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
  retention_in_days = 14
}

resource "aws_iam_role_policy_attachment" "eni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaENIManagementAccess"
  role = aws_iam_role.iam_for_lambda.id
}

resource "aws_iam_role_policy_attachment" "basic_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role = aws_iam_role.iam_for_lambda.id
}

resource "aws_iam_role_policy" "policy" {
  policy = var.policy_json
  role = aws_iam_role.iam_for_lambda.id
}

resource "aws_lambda_function" "lambda" {
  function_name = var.function_name
  package_type = "Image"
  image_uri = var.image_uri
  role = aws_iam_role.iam_for_lambda.arn
  source_code_hash = base64sha256(timestamp())
  timeout = var.timeout
  memory_size = var.memory_size
  tags = merge(var.tags, { Name = var.function_name })

  environment {
    variables = var.environment_variables
  }

  vpc_config {
    security_group_ids = var.security_group_ids
    subnet_ids = var.subnet_ids
  }

  depends_on = [
    aws_iam_role_policy_attachment.basic_policy,
    aws_iam_role_policy_attachment.eni_policy,
    aws_iam_role_policy.policy,
    aws_cloudwatch_log_group.lambda,
  ]
}
