// export aks cluster data for auth into cluster
data "azurerm_kubernetes_cluster" "primary" {
  depends_on          = [azurerm_kubernetes_cluster.primary] // refresh cluster state before reading
  name                = azurerm_kubernetes_cluster.primary.name
  resource_group_name = azurerm_resource_group.primary.name
}

// k8s provider declaration & auth
provider "kubernetes" {
  host                   = data.azurerm_kubernetes_cluster.primary.kube_config.0.host
  client_certificate     = base64decode(data.azurerm_kubernetes_cluster.primary.kube_config.0.client_certificate)
  client_key             = base64decode(data.azurerm_kubernetes_cluster.primary.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.primary.kube_config.0.cluster_ca_certificate)
}

resource "kubernetes_namespace" "coder-ns" {
  metadata {
    name = var.namespace
  }
}

resource "kubernetes_namespace" "azure-workload-identity-ns" {
  metadata {
    name = "azure-workload-identity-system"
  }
}

// helm provider declaration
provider "helm" {
  kubernetes {
    host                   = data.azurerm_kubernetes_cluster.primary.kube_config.0.host
    client_certificate     = base64decode(data.azurerm_kubernetes_cluster.primary.kube_config.0.client_certificate)
    client_key             = base64decode(data.azurerm_kubernetes_cluster.primary.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.primary.kube_config.0.cluster_ca_certificate)
  }
}

// pull down Azure workload identity helm chart and install it
resource "helm_release" "azure-workload-identity-chart" {
  name       = "azure-workload-identity-chart"
  repository = "https://azure.github.io/azure-workload-identity/charts"
  chart = "workload-identity-webhook"
  version = var.awi_version
  namespace = "azure-workload-identity-system"
  set {
    name = "azureTenantID"
    value = var.tenant_id
  }
  depends_on = [
    kubernetes_namespace.azure-workload-identity-ns
  ]
}

// pull down Coder helm chart & install it
resource "helm_release" "cdr-chart" {
  name       = "cdr-chart"
  repository = "https://helm.coder.com"
  chart      = "coder"
  version    = var.coder_version
  namespace  = var.namespace
  depends_on = [
    kubernetes_namespace.coder-ns
  ]
}

// apply annotations to coder service account
// need to do this hackily due to https://github.com/hashicorp/terraform-provider-kubernetes/issues/692
// used approach from https://github.com/hashicorp/terraform-provider-kubernetes/issues/723#issuecomment-914593460
resource "null_resource" "patch-coder-service-account" {
  triggers = {
    always_run = "${timestamp()}"
  }

  provisioner "local-exec" {
    command = "kubectl -n $CODER_NS annotate --overwrite serviceaccount $CODER_SA azure.workload.identity/client-id=$CLIENT_ID"
    environment = {
      CODER_NS  = var.namespace
      CODER_SA  = var.serviceaccount
      CLIENT_ID = azurerm_user_assigned_identity.coderd-identity.client_id
    }
  }

  depends_on = [
    helm_release.cdr-chart,
    azurerm_user_assigned_identity.coderd-identity
  ]
}

resource "null_resource" "patch-coder-service-account-label" {
  triggers = {
    always_run = "${timestamp()}"
  }

  provisioner "local-exec" {
    command = "kubectl -n $CODER_NS label --overwrite serviceaccount $CODER_SA azure.workload.identity/use=true"
    environment = {
      CODER_NS  = var.namespace
      CODER_SA  = var.serviceaccount
    }
  }

  depends_on = [
    helm_release.cdr-chart,
    azurerm_user_assigned_identity.coderd-identity,
    null_resource.patch-coder-service-account
  ]
}
