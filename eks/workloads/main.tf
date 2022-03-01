locals {
  overrides = jsondecode(var.overrides)

  keyed_charts = {
    for chart in var.charts :
    "${chart["namespace"]}:${chart["name"]}" => {
      name       = chart["name"]
      namespace  = chart["namespace"]
      repository = chart["repository"]
      chart      = chart["chart"]
      version    = chart["version"]
      values     = jsondecode(chart["values"])
    }
    if lookup(chart, "enabled", true) && !contains(var.disabled, chart["name"])
  }

  secrets = toset(flatten([
    for namespace, secrets in var.secrets : [
      for secret in secrets : [
        "${namespace}/${secret}"
      ]
    ]
  ]))
}

# Create empty secrets to be filled in later
resource "kubernetes_secret" "configs" {
  for_each = local.secrets

  metadata {
    name      = basename(each.value)
    namespace = dirname(each.value)

  }

  # Data will be filled in later
  data = {}

  # Ignore changes to data
  lifecycle {
    ignore_changes = [data]
  }
}

module "yaml_resources" {
  source       = "git::https://github.com/Mesitis/canopy-terraform-modules//eks/kubectl/kubeconfig"
  cluster_name = var.cluster_name
  manifests    = var.yaml_resources
  validate     = false
}

resource "helm_release" "app" {
  for_each    = local.keyed_charts
  name        = each.value["name"]
  namespace   = each.value["namespace"]
  repository  = each.value["repository"]
  chart       = each.value["chart"]
  version     = each.value["version"]
  max_history = 5
  timeout     = 360
  # 6 minutes

  values = [
    yamlencode(each.value["values"]),
    contains(keys(local.overrides), each.value["name"]) ? yamlencode(local.overrides[each.value["name"]]) : ""
  ]
}