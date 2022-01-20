variable "cluster_name" {
  type        = string
  description = "Name of the cluster"
}

data "aws_eks_cluster" "this" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "this" {
  name = var.cluster_name
}

locals {
  kubeconfig = yamlencode({
    apiVersion      = "v1"
    kind            = "Config"
    current-context = "terraform"
    clusters        = [
      {
        name    = data.aws_eks_cluster.this.name
        cluster = {
          certificate-authority-data = data.aws_eks_cluster.this.certificate_authority[0].data
          server                     = data.aws_eks_cluster.this.endpoint
        }
      }
    ]
    contexts        = [
      {
        name    = "terraform"
        context = {
          cluster = data.aws_eks_cluster.this.name
          user    = "terraform"
        }
      }
    ]
    users           = [
      {
        name = "terraform"
        user = {
          token = data.aws_eks_cluster_auth.this.token
        }
      }
    ]
  })
}

output "kubeconfig" {
  value = local.kubeconfig
}