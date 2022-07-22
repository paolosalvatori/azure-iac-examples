param domainName string
param tags object
param location string
param cert object
param rootCert object
param winVmPassword string
param vNets array
param sshPublicKey string
param aksAdminGroupObjectId string

var privateDomainName = 'internal.${domainName}'
var suffix = uniqueString(resourceGroup().id)
var keyVaultName = 'kv-${suffix}'
var azSeparatedAddressprefix = split(vNets[0].subnets[2].addressPrefix, '.')
var appGwySeparatedAddressprefix = split(vNets[0].subnets[0].addressPrefix, '.')
var azFirewallPrivateIpAddress = '${azSeparatedAddressprefix[0]}.${azSeparatedAddressprefix[1]}.${azSeparatedAddressprefix[2]}.4'
var appGwyPrivateIpAddress = '${appGwySeparatedAddressprefix[0]}.${appGwySeparatedAddressprefix[1]}.${appGwySeparatedAddressprefix[2]}.200'

module azMonitorModule './modules/azmon.bicep' = {
  name: 'modules-azmon'
  params: {
    suffix: suffix
  }
}

module udrModule './modules/udr.bicep' = {
  name: 'module-udr'
  params: {
    suffix: suffix
    azureFirewallPrivateIpAddress: azFirewallPrivateIpAddress
  }
}

module nsgModule './modules/nsg.bicep' = {
  name: 'module-nsg'
  params: {
    location: location
    appGatewayPublicIpAddress: '1.1.1.1'
    suffix: suffix
  }
}

// Virtual Networks
module vNetsModule './modules/vnets.bicep' = [for (item, i) in vNets: {
  name: 'module-vnet-${i}'
  scope: resourceGroup(resourceGroup().name)
  params: {
    suffix: suffix
    location: location
    vNet: item
    tags: tags
  }
  dependsOn: [
    udrModule
    nsgModule
  ]
}]

// Virtual Network Peering
module peeringModule './modules/peering.bicep' = {
  name: 'module-peering'
  scope: resourceGroup(resourceGroup().name)
  params: {
    suffix: suffix
    vNets: vNets
    isGatewayDeployed: false
  }
  dependsOn: [
    vNetsModule
  ]
}

// ACR 
module acr 'modules/acr.bicep' = {
  name: 'module-acr'
  params: {
    location: location
    tags: tags
    prefix: suffix
  }
}

// KeyVault
module keyvault 'modules/keyvault.bicep' = {
  name: 'module-keyvault'
  params: {
    location: location
    name: keyVaultName
    tenantId: tenant().tenantId
  }
}

// Azure Firewall
/* module azureFirewallModule './modules/azfirewall.bicep' = {
  name: 'module-azureFirewall'
  params: {
    suffix: suffix
    location: location
    retentionInDays: 7
    workspaceId: azMonitorModule.outputs.workspaceId
    firewallSubnetRef: vNetsModule[0].outputs.subnetRefs[2].id
    sourceAddressRangePrefix: [
      '10.0.0.0/8'
    ]
  }
} */

// Azure Bastion
module bastionModule './modules/bastion.bicep' = {
  dependsOn: [
    //azureFirewallModule
  ]
  name: 'module-bastion'
  params: {
    location: location
    subnetId: vNetsModule[0].outputs.subnetRefs[3].id
    suffix: suffix
  }
}

// Windows VM
module winVmModule './modules/winvm.bicep' = {
  dependsOn: [
    bastionModule
  ]
  name: 'module-winvm'
  params: {
    windowsOSVersion: '2016-Datacenter'
    adminPassword: winVmPassword
    adminUserName: 'localadmin'
    location: location
    subnetId: vNetsModule[0].outputs.subnetRefs[1].id
    suffix: suffix
    vmSize: 'Standard_D2_v3'
  }
}

// Linux VM
module linuxVM './modules/linuxvm.bicep' = {
  name: 'module-linuxvm'
  params: {
    location: location
    subnetId: vNetsModule[0].outputs.subnetRefs[1].id
    adminUserName: 'azureuser'
    suffix: suffix
    sshKey: sshPublicKey
  }
}

// Private DNS zones
resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  location: 'global'
  tags: tags
  name: privateDomainName
  properties: {}
}

// APIM
module apiManagementModule './modules/apim.bicep' = {
  dependsOn: [
    azMonitorModule
  ]
  name: 'module-apim'
  params: {
    tags: tags
    location: location
    retentionInDays: 30
    workspaceId: azMonitorModule.outputs.workspaceId
    privateDnsZoneName: privateDnsZone.name
    hubVnetId: vNetsModule[0].outputs.vnetRef
    spokeVnetId: vNetsModule[1].outputs.vnetRef
    apimSku: {
      name: 'Developer'
      capacity: 1
    }
    deployCertificates: true
    proxyHostName: 'proxy.${privateDomainName}'
    portalHostName: 'portal.${privateDomainName}'
    managementHostName: 'management.${privateDomainName}'
    certificate: cert.CertValue
    certificatePassword: cert.CertPassword
    subnetId: vNetsModule[0].outputs.subnetRefs[4].id
  }
}

// Application Gateway
module applicationGatewayModule './modules/appgateway.bicep' = {
  dependsOn: [
    azMonitorModule
    privateDnsZone
  ]
  name: 'module-applicationGateway'
  params: {
    suffix: suffix
    location: location
    privateDnsZoneName: privateDomainName
    workspaceId: azMonitorModule.outputs.workspaceId
    apimGatewaySslCertPassword: cert.CertPassword
    frontEndPort: 443
    internalFrontendPort: 8080
    retentionInDays: 7
    externalProxyHostName: 'api.${domainName}'
    externalPortalHostName: 'portal.${domainName}'
    externalManagementHostName: 'management.${domainName}'
    internalProxyHostName: 'proxy.${privateDomainName}'
    internalPortalHostName: 'portal.${privateDomainName}'
    internalManagementHostName: 'management.${privateDomainName}'
    rootSslCert: rootCert.CertValue
    apimGatewaySslCert: cert.CertValue
    apimPrivateIpAddress: appGwyPrivateIpAddress
    gatewaySku: {
      name: 'WAF_v2'
      tier: 'WAF_v2'
      capacity: '1'
    }
    requestTimeOut: 180
    skuName: 'Standard'
    subnetId: vNetsModule[0].outputs.subnetRefs[0].id
  }
}

module aks 'modules/aks.bicep' = {
  name: 'module-aks'
  params: {
    location: location
    tags: tags
    addOns: {}
    enablePrivateCluster: false
    aksSystemSubnetId: vNetsModule[1].outputs.subnetRefs[1].id
    aksUserSubnetId: vNetsModule[1].outputs.subnetRefs[1].id
    prefix: suffix
    logAnalyticsWorkspaceId: azMonitorModule.outputs.workspaceId
    sshPublicKey: sshPublicKey
    adminGroupObjectID: aksAdminGroupObjectId
    linuxAdminUserName: 'aksuser'
  }
}

// NSG Update
module networkSecurityGroupUpdateModule './modules/nsg.bicep' = {
  name: 'module-nsgupdate'
  params: {
    location: location
    suffix: suffix
    appGatewayPublicIpAddress: applicationGatewayModule.outputs.appGwyPublicIpAddress
  }
}

// Azure Public DNS records
module appGwyApiPublicDnsRecord 'modules/publicdns.bicep' = {
  scope: resourceGroup('external-dns-zones-rg')
  name: 'module-appgwy-public-dns-record'
  params: {
    zoneName: domainName
    ipAddress: applicationGatewayModule.outputs.appGwyPublicIpAddress
    recordName: 'api'
  }
}

module appGwyApimPortalPublicDnsRecord 'modules/publicdns.bicep' = {
  scope: resourceGroup('external-dns-zones-rg')
  name: 'module-appgwy-apim-portal-public-dns-record'
  params: {
    zoneName: domainName
    ipAddress: applicationGatewayModule.outputs.appGwyPublicIpAddress
    recordName: 'portal'
  }
}

module appGwyApimManagementPublicDnsRecord 'modules/publicdns.bicep' = {
  scope: resourceGroup('external-dns-zones-rg')
  name: 'module-appgwy-apim-management-public-dns-record'
  params: {
    zoneName: domainName
    ipAddress: applicationGatewayModule.outputs.appGwyPublicIpAddress
    recordName: 'management'
  }
}

output appGwyName string = applicationGatewayModule.outputs.appGwyName
output appGwyId string = applicationGatewayModule.outputs.appGwyId
output appGwyFqdn string = applicationGatewayModule.outputs.appGwyPublicDnsName
output appGwyPublicIpAddress string = applicationGatewayModule.outputs.appGwyPublicIpAddress
output apimPrivateIpAddress string = apiManagementModule.outputs.apimPrivateIpAddress
output apimName string = apiManagementModule.outputs.apimName
output apimManagedIdentity string = apiManagementModule.outputs.apimManagedIdentityPrincipalId
output aksClusterName string = aks.outputs.aksClusterName
output acrName string = acr.outputs.registryName
