terraform {
  required_providers {
    helm = {
      source = "hashicorp/helm"
      version = "~> 2.3"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "~> 2.5"
    }
    local = {
      source = "hashicorp/local"
      version = "~> 2.1"
    }
    null = {
      source = "hashicorp/null"
      version = "~> 3.1"
    }
    template = {
      source = "hashicorp/template"
      version = "~> 2.2"
    }
  }
  required_version = ">= 0.13"
}
