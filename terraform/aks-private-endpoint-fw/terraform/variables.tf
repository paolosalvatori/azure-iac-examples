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

variable "kubernetesVersion" {
  type    = string
  default = "1.16.9"
}

variable "aksNodeSku" {
  type    = string
  default = "Standard_D2_v2"

}

variable "bastionVmSku" {
  type    = string
  default = "Standard_B1ms"
}

variable "sshKey" {
  type    = string
}

data local_file "cloudinit" {
  filename = "./cloudinit.txt"
}
