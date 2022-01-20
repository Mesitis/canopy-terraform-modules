module "kubeconfig_generator" {
  source       = "git::https://github.com/Mesitis/canopy-terraform-modules//eks/kubectl/kubeconfig"
  cluster_name = var.cluster_name
}

resource "null_resource" "kubectl" {
  triggers = {
    kubeconfig = base64encode(module.kubeconfig_generator.kubeconfig)
    cmd  = "kubectl ${var.args} --kubeconfig <(echo $KUBECONFIG | base64 --decode)"
  }
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    environment = {
      KUBECONFIG = self.triggers.kubeconfig
    }
    command = self.triggers.cmd
  }
}