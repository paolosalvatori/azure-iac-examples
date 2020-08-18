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
    "nonprod-aks-rg"
  ]
}

/* 
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
 */

variable "location" {
  default = "australiaeast"
}

variable "vnets" {
  type = map(object({
    name = string
    address_space = list(string)
    subnets = map(object({ 
      name = string
      address_prefix = string
     }))
  }))
  default = {
      name = "hub-vnet"
      address_space = ["10.0.0.0/16"]
      subnets = [
          {
            name           = "GatewaySubnet"
            address_prefix = "10.0.0.0/24"
          },
          {
            name           = "AzureFirewallSubnet"
            address_prefix = "10.0.1.0/24"
          },
          {
            name           = "BastionSubnet"
            address_prefix = "10.0.2.0/24"
          },
          {
            name           = "AppGatewaySubnet"
            address_prefix = "10.0.3.0/24"
          }
        ]
    },
    {
      name = "prod-spoke-vnet"
      address_space = ["10.1.0.0/16"]
    },
    {
      name = "nonprod-spoke-vnet"
      address_space = ["10.2.0.0/16"]
    }
}


variable "hub_subnets" {
  default = [
    {
      name             = "GatewaySubnet"
      address_prefixes = ["10.0.0.0/24"]
    },
    {
      name             = "AzureFirewallSubnet"
      address_prefixes = ["10.0.1.0/24"]
    },
    {
      name             = "BastionSubnet"
      address_prefixes = ["10.0.2.0/24"]
    },
    {
      name             = "AppGatewaySubnet"
      address_prefixes = ["10.0.3.0/24"]
    }
  ]
}

variable "spoke_subnets" {
  default = [
    {
      name             = "prod-aks-subnet"
      address_prefixes = ["10.1.0.0/24"]
    },
    {
      name             = "prod-web-subnet"
      address_prefixes = ["10.1.1.0/24"]
    },
    {
      name             = "prod-sql-subnet"
      address_prefixes = ["10.1.2.0/24"]
    }
  ]
}

variable "nonprod_spoke_subnets" {
  default = [
    {
      name             = "nonprod-aks-subnet"
      address_prefixes = ["10.1.0.0/24"]
    },
    {
      name             = "nonprod-web-subnet"
      address_prefixes = ["10.1.1.0/24"]
    },
    {
      name             = "nonprod-sql-subnet"
      address_prefixes = ["10.1.2.0/24"]
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
  type    = string
  default = "192.168.88.0/24"
}

variable "shared_vpn_secret" {
  type = string
}

variable "admin_user_name" {
  type    = string
  default = "localadmin"
}

data local_file "cloudinit" {
  filename = "./cloudinit.txt"
}
