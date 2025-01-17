// export access token for auth into cluster
data "google_client_config" "default" {}

// k8s provider declaration & auth
provider "kubernetes" {
  host                   = "https://${google_container_cluster.primary.endpoint}"
  cluster_ca_certificate = base64decode(google_container_cluster.primary.master_auth.0.cluster_ca_certificate)
  token                  = data.google_client_config.default.access_token
}

// k8s resource definitions for coder
resource "kubernetes_namespace" "coder-ns" {
  metadata {
    name = "coder"
  }
}

// helm provider declaration
provider "helm" {
  kubernetes {
    host                   = "https://${google_container_cluster.primary.endpoint}"
    cluster_ca_certificate = base64decode(google_container_cluster.primary.master_auth.0.cluster_ca_certificate)
    token                  = data.google_client_config.default.access_token
  }
}

// pull down coder helm chart & install it
resource "helm_release" "cdr-chart" {
  name       = "coder"
  repository = "https://helm.coder.com"
  chart      = "coder"
  version    = var.coder_version
  namespace  = var.namespace
  values     = [ "${file("values.yaml")}" ]
}
