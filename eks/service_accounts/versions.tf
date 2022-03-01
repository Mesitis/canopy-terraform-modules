terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 3.62"
      configuration_aliases = [aws.roles]
    }
  }
  required_version = ">= 0.13"
}

