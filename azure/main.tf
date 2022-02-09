terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.95.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.3.2"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.2.0"
    }
    null = {
      source = "hashicorp/null"
      version = "3.1.0"
    }
  }
  required_version = "~> 1.1.0"
}
