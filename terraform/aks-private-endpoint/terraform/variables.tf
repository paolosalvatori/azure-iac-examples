variable "tags" {
  default = {
    "environment" = "test"
    "costcentre"  = "123456"
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
  default = "Standard_D2_v2"
}

variable "max_pods" {
  type = string
  default = 30
}

variable "bastion_vm_sku" {
  type    = string
  default = "Standard_F2s_v2"
}

variable "ssh_key" {
  type = string
  default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDCKEnblRrHUsUf2zEhDC4YrXVDTf6Vj3eZhfIT22og0zo2hdpfUizcDZ+i0J4Bieh9zkcsGMZtMkBseMVVa5tLSNi7sAg79a8Bap5RmxMDgx53ZCrJtTC3Li4e/3xwoCjnl5ulvHs6u863G84o8zgFqLgedKHBmJxsdPw5ykLSmQ4K6Qk7VVll6YdSab7R6NIwW5dX7aP2paD8KRUqcZ1xlArNhHiUT3bWaFNRRUOsFLCxk2xyoXeu+kC9HM2lAztIbUkBQ+xFYIPts8yPJggb4WF6Iz0uENJ25lUGen4svy39ZkqcK0ZfgsKZpaJf/+0wUbjqW2tlAMczbTRsKr8r cbellee@CB-SBOOK-1809"
}

variable "on_premises_router_public_ip_address" {
  type = string
  default = "110.150.196.195"
}

variable "on_premises_router_private_cidr" {
  type = string
  default = "192.168.88.0/24"
}

data local_file "cloudinit" {
  filename = "./cloudinit.txt"
}
