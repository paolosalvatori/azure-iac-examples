variable "tags" {
  default = {
    "environment" = "test"
    "costcentre"  = "12345"
  }
}

variable "prefix" {
  default = "aks-az"
}

variable "resource_group_name" {
  default = "aks-az-rg"
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
  default = "Standard_F2s_v2"
}

variable "max_pods" {
  type = number
  default = 100
}

variable "os_disk_size_gb" {
  type = number
  default = 250
}

variable "ssh_key" {
  type = string
}
