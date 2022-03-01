output "releases" {
  value     = helm_release.app
  sensitive = true
}