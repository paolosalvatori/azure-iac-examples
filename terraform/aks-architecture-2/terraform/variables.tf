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

variable "resource_groups" {
  default = [
    "network-rg",
    "mgmt-rg",
    "prod-aks-rg",
    "nonprod-aks-rg",
  ]
}

variable "location" {
  default = "australiaeast"
}

variable "vnets" {
  type = list(object({
    name = string,
    address_space = list(string),
    subnets = map(object({ 
      subnet_increment = number
     }))
  }))
  default = [
    {
      name = "hub-vnet",
      address_space = ["10.0.0.0/16"]
      subnets = {
          "GatewaySubnet" = {
            subnet_increment = 0
          },
            "AzureFirewallSubnet" = {
            subnet_increment = 1
          },
          "BastionSubnet" = {
            subnet_increment = 2
          },
          "AppGatewaySubnet" = {
            subnet_increment = 3
          }
       }
    },
    {
      name = "prod-spoke-vnet"
      address_space = ["10.1.0.0/16"]
      subnets = {
          "prod-aks-subnet" = {
            subnet_increment = 0
          },
          "prod-web-subnet" = {
            subnet_increment = 1
          },
          "prod-sql-subnet" = {
            subnet_increment = 2
          }
       }
    },
    {
      name = "nonprod-spoke-vnet"
      address_space = ["10.2.0.0/16"]
      subnets = {
          "nonprod-aks-subnet" = {
            subnet_increment = 0
          },
          "nonprod-web-subnet" = {
            subnet_increment = 1
          },
          "nonprod-sql-subnet" = {
            subnet_increment = 2
          }
       }
    },
  ]
}

variable "aks_clusters" {
  type = list(object({
    name = string
    resource_group_name = string
    vnet_name = string
  }))
  default = [
    {
      "name" = "prod-aks-cluster"
      "resource_group_name" = "prod-aks-rg"
      "vnet_name" = "prod-spoke-vnet"
    },
    {
      "name" = "nonprod-aks-cluster"
      "resource_group_name" = "nonprod-aks-rg"
      "vnet_name" = "nonprod-spoke-vnet"
    }
  ]
}

variable "kubernetes_version" {
  type    = string
  default = "1.17.9"
}

variable "aks_node_sku" {
  type    = string
  default = "Standard_D2_v2"
}

variable "aks_max_pods" {
  type = number
  default = 200
}

variable "aks_node_count" {
  type = number
  default = 1
}

variable "aks_max_node_count" {
  type = number
  default = 5
}

variable "aks_admin_group_object_ids" {
  type = list(string)
  default = [
    "f6a900e2-df11-43e7-ba3e-22be99d3cede" # displayName": "aks-admin-group"
  ]
}

variable "aks_min_node_count" {
  type = number
  default = 1
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
  type    = string
  default = "192.168.88.0/24"
}

variable "shared_vpn_secret" {
  type = string
  default = "M1cr0soft123"
}

variable "admin_user_name" {
  type    = string
  default = "localadmin"
}

data local_file "cloudinit" {
  filename = "./cloudinit.txt"
}
