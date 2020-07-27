variable "tags" {
  default = {
    "environment" = "test"
    "costcentre"  = "12345"
  }
}

variable "prefix" {
  default = "azure-aks"
}

variable "resource_group_name" {
  default = "azure-aks-rg"
}

variable "location" {
  default = "australiaeast"
}

variable "kubernetes_version" {
  type    = string
  default = "1.16.10"
}

variable "aks_node_sku" {
  type    = string
  default = "Standard_F8s_v2"
}

variable "ssh_key" {
  type = string
}
