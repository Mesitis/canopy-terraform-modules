output "lambda_arn" {
  value = aws_lambda_function.lambda.arn
}

output "lambda_invoke_arn" {
  value = aws_lambda_function.lambda.invoke_arn
}

output "lambda_name" {
  value = aws_lambda_function.lambda.function_name
}

output "lambda_iam_role_arn" {
  value = var.iam_role_arn == "" ? aws_iam_role.iam_for_lambda[0].arn : var.iam_role_arn
}

