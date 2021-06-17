module "apply" {
  for_each     = var.manifests
  source       = "github.com/Mesitis/canopy-terraform-modules//eks/kubectl/raw"
  cluster_name = var.cluster_name
  args         = "apply --validate=${var.validate ? "true" : "false"} -f ${each.value}"

  # not used yet
  destroy_args = "delete --validate=${var.validate ? "true" : "false"} -f ${each.value}"
}