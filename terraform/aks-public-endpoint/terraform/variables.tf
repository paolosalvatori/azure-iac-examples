variable "tags" {
  default = {
    "environment" = "test"
    "costcentre"  = "12345"
  }
}

variable "prefix" {
  default = "aks-public-demo"
}

variable "resource_group_name" {
  default = "aks-public-demo-rg"
}

variable "location" {
  default = "australiaeast"
}

variable "kubernetes_version" {
  type    = string
  default = "1.16.9"
}

variable "aks_node_sku" {
  type    = string
  default = "Standard_F8s_v2"
}

variable "ssh_key" {
  type = string
}
