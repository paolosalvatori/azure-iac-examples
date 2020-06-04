variable "tags" {
  default = {
    "environment" = "test"
    "costcentre"  = "12345"
  }
}

variable "prefix" {
  default = "aks-pe-fw"
}

variable "resource_group_name" {
  default = "aks-pe-fw-rg"
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
  default = "Standard_D2_v2"

}

variable "bastion_vm_sku" {
  type    = string
  default = "Standard_B1ms"
}

variable "ssh_key" {
  type = string
}

variable "home_public_ip_address" {
  type = string
}

variable "home_private_cidr" {
  type = string
  default = "192.168.88.0/24"
}

variable "shared_vpn_secret" {
  type = string
}

data local_file "cloudinit" {
  filename = "./cloudinit.txt"
}
