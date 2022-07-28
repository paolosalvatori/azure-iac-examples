param domainName string
param tags object
param location string
param cert object
param rootCert object
param vNets array
param sshPublicKey string
param aksAdminGroupObjectId string
param orderApiYaml string
param productApiYaml string
param orderApiPoicyXml string
param productApiPoicyXml string
param kubernetesSpaIpAddress string

var privateDomainName = 'internal.${domainName}'
var suffix = uniqueString(resourceGroup().id)
var appGwySeparatedAddressprefix = split(vNets[0].subnets[0].addressPrefix, '.')
var appGwyPrivateIpAddress = '${appGwySeparatedAddressprefix[0]}.${appGwySeparatedAddressprefix[1]}.${appGwySeparatedAddressprefix[2]}.200'

module azMonitorModule './modules/azmon.bicep' = {
  name: 'modules-azmon'
  params: {
    suffix: suffix
    location: location
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

/* // KeyVault
module keyvault 'modules/keyvault.bicep' = {
  name: 'module-keyvault'
  params: {
    location: location
    name: keyVaultName
    tenantId: tenant().tenantId
  }
}

// Azure Bastion
module bastionModule './modules/bastion.bicep' = {
  name: 'module-bastion'
  params: {
    location: location
    subnetId: vNetsModule[0].outputs.subnetRefs[3].id
    suffix: suffix
  }
} */

/* 
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
 */
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
    vNetsModule
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

// Import Open Api Definitions
module orderOpenApiDefinition 'modules/api.bicep' = {
  name: 'module-order-api'
  params: {
    apimName: apiManagementModule.outputs.apimName
    apiName: 'order-api'
    apiPath: 'api/order'
    backendUrl: 'http://10.2.1.4'
    displayName: 'Order API'
    isSubscriptionRequired: false
    openApiYaml: orderApiYaml
    xmlPolicy: orderApiPoicyXml
  }
}

module productOpenApiDefinition 'modules/api.bicep' = {
  name: 'module-product-api'
  params: {
    apimName: apiManagementModule.outputs.apimName
    apiName: 'product-api'
    apiPath: 'api/product'
    backendUrl: 'http://10.2.1.5'
    displayName: 'Product API'
    isSubscriptionRequired: false
    openApiYaml: productApiYaml
    xmlPolicy: productApiPoicyXml
  }
}

// Application Gateway
module applicationGatewayModule './modules/appgateway.bicep' = {
  dependsOn: [
    vNetsModule
    azMonitorModule
    privateDnsZone
  ]
  name: 'module-applicationGateway'
  params: {
    suffix: suffix
    location: location
    kubernetesSpaIpAddress: kubernetesSpaIpAddress
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

// acrPull role assignment to AKS cluster identity
/* module acrPullRoleAssignment 'modules/acr_pull_role.bicep' = {
  name: 'module-acr-pull-role-assignment'
  params: {
    acrName: acr.outputs.registryName
    aksClusterName: aks.outputs.aksClusterName
  }
}
 */

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
