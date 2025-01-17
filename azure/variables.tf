// variable declarations
variable "name" {}
variable "node_vm_size" {}
variable "location" {}
variable "network_policy" {}
variable "network_plugin" {}
variable "address_space" {}
variable "os_disk_size_gb" {}
variable "namespace" {}
variable "serviceaccount" {}
variable "coder_version" {}
variable "awi_version" {}
variable "tenant_id" {
  sensitive = true
}
variable "app_id" {
  sensitive = true
}
variable "subscription_id" {
  sensitive = true
}
variable "oidc_issuer" {
  sensitive = true
}
variable "min_count" {}
variable "max_count" {}
