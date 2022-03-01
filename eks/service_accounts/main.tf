data "aws_caller_identity" "roles" {
  provider = aws.roles
}

data "aws_eks_cluster" "this" {
  name = var.cluster_name
}

data "aws_kms_alias" "s3" {
  name = "alias/environment/${var.name}/s3"
}

locals {
  kms_s3_usage_policy = {
    name_prefix = "s3-kms-key-",
    statements = [
      {
        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:DescribeKey",
          "kms:GenerateDataKey*",
          "kms:ReEncrypt*"
        ]
        Resource = [
          data.aws_kms_alias.s3.target_key_arn
        ]
        Effect = "Allow"
      }
    ]
  }

  oidc_provider = split("https://", data.aws_eks_cluster.this.identity.0.oidc.0["issuer"])[1]

  role_creation_map = {
    for account in tolist(var.service_accounts) :
    "${var.role_name_prefix}eks-${data.aws_eks_cluster.this.name}-${account["name"]}-${account["namespace"]}-sa${var.role_name_suffix}" => {
      attach_policy_arns = account["attach_policy_arns"]

      # Generate inline policies based on the buckets given
      # if any bucket is given, also ensure the s3 kms key usage permission is provided.
      inline_policies = toset(concat(
        tolist(account["inline_policies"]),
        length(account["rw_buckets"]) == 0 ? [] : [
          {
            name_prefix = "s3-rw-",
            statements = [
              {
                Action = [
                  "s3:GetObject*",
                  "s3:List*",
                  "s3:PutObject*",
                  "s3:AbortMultipartUpload",
                  "s3:DeleteObject"
                ]
                Resource = flatten([
                  for bucket in account["rw_buckets"] :
                  [
                    "arn:aws:s3:::${bucket}",
                    "arn:aws:s3:::${bucket}/*"
                  ]
                ])
                Effect = "Allow"
              }
            ]
          }
        ],
        length(account["ro_buckets"]) == 0 ? [] : [
          {
            name_prefix = "s3-ro-",
            statements = [
              {
                Action = [
                  "s3:GetObject*",
                  "s3:List*"
                ]
                Resource = flatten([
                  for bucket in account["ro_buckets"] :
                  [
                    "arn:aws:s3:::${bucket}",
                    "arn:aws:s3:::${bucket}/*"
                  ]
                ])
                Effect = "Allow"
              }
            ]
          }
        ],
        length(account["ro_buckets"]) > 0 || length(account["ro_buckets"]) > 0 ? [local.kms_s3_usage_policy] : []
      ))
      with_k8s_service_account = account["with_k8s_service_account"]
      namespace                = account["namespace"]
      name                     = account["name"]
    }
  }

  sa_creation_map = {
    for key_name in keys(local.role_creation_map) :
    key_name => local.role_creation_map[key_name]
    if local.role_creation_map[key_name]["with_k8s_service_account"]
  }

  flattened_policy_attachments = flatten([
    for name in keys(local.role_creation_map) : [
      for policy_arn in local.role_creation_map[name]["attach_policy_arns"] :
      {
        role       = name
        policy_arn = policy_arn
      }
    ]
  ])

  unique_mapped_policy_attachments = {
    for it in flatten(local.flattened_policy_attachments) :
    "${it["role"]}-${md5(it["policy_arn"])}" => {
      policy_arn = it.policy_arn
      role       = it.role
    }
  }

  flattened_inline_policy_attachments = flatten([
    for name in keys(local.role_creation_map) : [
      for inline_policy in local.role_creation_map[name]["inline_policies"] :
      {
        role               = name
        policy_name_prefix = inline_policy["name_prefix"]
        statements         = inline_policy["statements"]
      }
    ]
  ])


  unique_mapped_inline_policy_attachments = {
    for it in flatten(local.flattened_inline_policy_attachments) :
    "${it["role"]}-${it["policy_name_prefix"]}" => {
      role               = it["role"]
      policy_name_prefix = it["policy_name_prefix"]
      statements         = it["statements"]
    }
  }
}

resource "aws_iam_role" "service_account_role" {
  for_each           = local.role_creation_map
  name               = each.key
  provider           = aws.roles
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::${data.aws_caller_identity.roles.account_id}:oidc-provider/${local.oidc_provider}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "${local.oidc_provider}:sub": "system:serviceaccount:${each.value["namespace"]}:${each.value["name"]}"
        }
      }
    }
  ]
}
EOF
}


resource "kubernetes_service_account" "service_account" {
  for_each = local.sa_creation_map

  metadata {
    name      = each.value["name"]
    namespace = each.value["namespace"]
    labels = {
      aws-usage = "application"
      type      = "aws-iam-serviceaccount"
    }
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.service_account_role[each.key].arn
    }
  }

  automount_service_account_token = true
}

resource "aws_iam_role_policy_attachment" "arn-attachments" {
  for_each   = local.unique_mapped_policy_attachments
  provider   = aws.roles
  role       = aws_iam_role.service_account_role[each.value["role"]].name
  policy_arn = each.value["policy_arn"]
}


resource "aws_iam_role_policy" "inline-attachments" {
  for_each    = local.unique_mapped_inline_policy_attachments
  provider    = aws.roles
  name_prefix = each.value["policy_name_prefix"]
  role        = aws_iam_role.service_account_role[each.value["role"]].name
  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = each.value["statements"]
  })
}