data "aws_eks_cluster" "this" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "this" {
  name = var.cluster_name
}

resource "null_resource" "cluster_registration" {
  triggers = {
    cluster_name = var.cluster_name
    args         = var.args
  }

  provisioner "local-exec" {
    command = "/bin/bash ${path.module}/wrapper.sh ${self.triggers.args}"
    interpreter = [
      "/bin/bash", "-c"
    ]
    environment = {
      CLUSTER_NAME   = self.triggers.cluster_name
      CA_CERTIFICATE = base64decode(data.aws_eks_cluster.this.certificate_authority.0.data)
      KUBESERVER     = data.aws_eks_cluster.this.endpoint
      KUBETOKEN      = data.aws_eks_cluster_auth.this.token
    }
  }
  //
  //  dynamic "provisioner" {
  //    for_each = var.destroy_args == "" ? [] : [true]
  //    labels = ["local-exec"]
  //    content {
  //      when    = destroy
  //      command = "/bin/bash ${path.module}/wrapper.sh ${self.triggers.destroy_args}"
  //      interpreter = [
  //        "/bin/bash", "-c"
  //      ]
  //      environment = {
  //        CLUSTER_NAME = self.triggers.cluster_name
  //        CA_CERTIFICATE = base64decode(data.aws_eks_cluster.this.certificate_authority.0.data)
  //        KUBESERVER = data.aws_eks_cluster.this.endpoint
  //        KUBETOKEN = data.aws_eks_cluster_auth.this.token
  //      }
  //    }
  //  }
}
