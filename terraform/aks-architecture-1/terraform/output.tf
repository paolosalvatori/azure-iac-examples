output "prod-aks-node-rg" {
  value = azurerm_kubernetes_cluster.prod_aks_cluster.node_resource_group
}

output "prod-aks-cluster-name" {
  value = azurerm_kubernetes_cluster.prod_aks_cluster.name
}

output "prod-aks-cluster-id" {
  value = azurerm_kubernetes_cluster.Pprod_aks_cluster.id
}

output "prod-aks-cluster-private-fqdn" {
  value = azurerm_kubernetes_cluster.prod_aks_cluster.private_fqdn
}

output "prod-kube-config" {
  value = azurerm_kubernetes_cluster.prod_aks_cluster.kube_config_raw
}

output "nonprod-aks-node-rg" {
  value = azurerm_kubernetes_cluster.nonprod_aks_cluster.node_resource_group
}

output "nonprod-aks-cluster-name" {
  value = azurerm_kubernetes_cluster.nonprod_aks_cluster.name
}

output "nonprod-aks-cluster-id" {
  value = azurerm_kubernetes_cluster.nonprod_aks_cluster.id
}

output "nonprod-aks-cluster-private-fqdn" {
  value = azurerm_kubernetes_cluster.nonprod_aks_cluster.private_fqdn
}

output "nonprod-kube-config" {
  value = azurerm_kubernetes_cluster.nonprod_aks_cluster.kube_config_raw
}

output "vnet-resource-group-name" {
  value = azurerm_resource_group.vnet_rg.name
}

output "hub-vnet-id" {
  value = azurerm_virtual_network.hub_vnet.id
}

output "prod-spoke-vnet-id" {
  value = azurerm_virtual_network.prod_spoke_vnet.id
}

output "nonprod-spoke-vnet-id" {
  value = azurerm_virtual_network.nonprod_spoke_vnet.id
}
