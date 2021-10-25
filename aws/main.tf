terraform {

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.53.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "= 2.4.1"
    }

    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.2.0"
    }
  }

  required_version = ">= 1.0.0"
}
