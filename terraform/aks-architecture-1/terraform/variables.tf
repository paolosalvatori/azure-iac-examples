variable "tags" {
  default = {
    "environment" = "test"
    "costcentre"  = "12345"
  }
}

resource "random_id" "laws" {
  byte_length = 4
}

variable "prefix" {
  default = "test"
}

variable "resource_group_name" {
  default = "aks-rg"
}

variable "vnet_resource_group_name" {
  default = "network-rg"
}

variable "mgmt_resource_group_name" {
  default = "mgmt-rg"
}

variable "prod_aks_resource_group_name" {
  default = "prod-aks-rg"
}

variable "nonprod_aks_resource_group_name" {
  default = "nonprod-aks-rg"
}

variable "location" {
  default = "australiaeast"
}

variable "kubernetes_version" {
  type    = string
  default = "1.17.3"
}

variable "aks_node_sku" {
  type    = string
  default = "Standard_D2_v2"

}

variable "bastion_vm_sku" {
  type    = string
  default = "Standard_F2s_v2"
}

variable "ssh_key" {
  type = string
}

variable "on_premises_router_public_ip_address" {
  type = string
}

variable "on_premises_router_private_cidr" {
  type = string
  default = "192.168.88.0/24"
}

variable "shared_vpn_secret" {
  type = string
}

variable "admin_user_name" {
  type = string
  default = "localadmin"
}

data local_file "cloudinit" {
  filename = "./cloudinit.txt"
}
