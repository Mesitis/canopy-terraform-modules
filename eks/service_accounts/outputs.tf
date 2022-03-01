output "aws_iam_roles" {
  value = {
    for role in aws_iam_role.service_account_role :
    role.name => role.arn
  }
}

output "kubernetes_service_accounts" {
  value = {
    for sa in kubernetes_service_account.service_account :
    sa.id => sa.metadata[0].annotations["eks.amazonaws.com/role-arn"]
  }
}
