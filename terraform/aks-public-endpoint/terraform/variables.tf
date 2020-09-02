variable "tags" {
  default = {
    "environment" = "test"
    "costcentre"  = "12345"
  }
}

variable "prefix" {
  default = "aks-private"
}

variable "resource_group_name" {
  default = "aks-private-rg"
}

variable "location" {
  default = "australiaeast"
}

variable "kubernetes_version" {
  type    = string
  default = "1.17.9"
}

variable "aks_node_sku" {
  type    = string
  default = "Standard_F8s_v2"
}

variable "ssh_key" {
  type = string
}
