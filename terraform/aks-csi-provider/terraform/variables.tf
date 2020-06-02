variable "tenant_id" {
}

variable "tags" {
  default = {
    "environment" = "test"
    "costcentre"  = "12345"
  }
}

variable "prefix" {
  default = "aks-csi-pod-id-demo"
}

variable "location" {
  default = "australiaeast"
}

variable "resourceGroupName" {
  default = "aks-csi-pod-id-demo-rg"
}

variable "kubernetesVersion" {
  type    = string
  default = "1.16.9"
}

variable "aksNodeSku" {
  type    = string
  default = "Standard_D2_v2"
}

variable "object_id" {
}

variable "kv_user_object_id" {
}

variable "secret_name" {
  default = "secret-sauce"
}

variable "secret_value" {
  default = "daddies"
}

variable "sshKey" {
  type    = string}
