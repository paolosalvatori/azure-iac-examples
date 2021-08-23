param domainName string
param tags object
param location string
param cert object
param rootCert object
param winVmPassword string
param functionAppId string

var privateDomainName = 'internal.${domainName}'
var suffix = uniqueString(resourceGroup().id)
// var azSeparatedAddressprefix = split(virtualNetworks[0].subnets[2].addressPrefix, '.')
// var appGwySeparatedAddressprefix = split(virtualNetworks[0].subnets[0].addressPrefix, '.')
// var azFirewallPrivateIpAddress = '${azSeparatedAddressprefix[0]}.${azSeparatedAddressprefix[1]}.${azSeparatedAddressprefix[2]}.4'
// var appGwyPrivateIpAddress = '${appGwySeparatedAddressprefix[0]}.${appGwySeparatedAddressprefix[1]}.${appGwySeparatedAddressprefix[2]}.200'

module azMonitorModule './modules/azmon.bicep' = {
  name: 'azureMonitorDeployment'
  params: {
    suffix: suffix
  }
}

module userDefinedRouteModule './modules/udr.bicep' = {
  name: 'udrDeployment'
  params: {
    suffix: suffix
    azureFirewallPrivateIpAddress: '10.1.2.4' //azFirewallPrivateIpAddress
  }
}

module networkSecurityGroupModule './modules/nsg.bicep' = {
  name: 'nsgDeployment'
  params: {
    location: location
    appGatewayPublicIpAddress: '1.1.1.1'
    suffix: suffix
  }
}

module hubVirtualNetworkModule 'modules/vnethub.bicep' = {
  name: 'hubVnetDeployment'
  dependsOn: [
    userDefinedRouteModule
    networkSecurityGroupModule
  ]
  params: {
    suffix: suffix
    tags: tags
  }
}

module spokeVirtualNetworkModule 'modules/vnetspoke.bicep' = {
  name: 'spokeVnetDeployment'
  dependsOn: [
    userDefinedRouteModule
    networkSecurityGroupModule
  ]
  params: {
    suffix: suffix
    tags: tags
  }
}

module virtualNetworkPeeringModule './modules/peerings.bicep' = {
  dependsOn: [
    hubVirtualNetworkModule
    spokeVirtualNetworkModule
  ]
  name: 'vNetPeeringDeployment'
  params: {
    hubVnet: hubVirtualNetworkModule.outputs.vnet
    spokeVnet: spokeVirtualNetworkModule.outputs.vnet
  }
}

module azureFirewallModule './modules/azfirewall.bicep' = {
  name: 'azureFirewallDeployment'
  params: {
    suffix: suffix
    retentionInDays: 7
    workspaceId: azMonitorModule.outputs.workspaceId
    firewallSubnetRef: hubVirtualNetworkModule.outputs.vnet.subnetRefs[2].id
    sourceAddressRangePrefix: [
      '10.0.0.0/8'
      '192.168.88.0/24'
    ]
  }
}

module bastionModule './modules/bastion.bicep' = {
  dependsOn: [
    azureFirewallModule
  ]
  name: 'bastionDeployment'
  params: {
    location: location
    subnetId: hubVirtualNetworkModule.outputs.vnet.subnetRefs[3].id
    suffix: suffix
  }
}

module winVmModule './modules/winvm.bicep' = {
  dependsOn: [
    bastionModule
  ]
  name: 'winVmDeployment'
  params: {
    windowsOSVersion: '2016-Datacenter'
    adminPassword: winVmPassword
    adminUserName: 'localadmin'
    location: location
    subnetId: hubVirtualNetworkModule.outputs.vnet.subnetRefs[1].id
    suffix: suffix
    vmSize: 'Standard_D2_v3'
  }
}

/* module funcAppModule './modules/funcapp.bicep' = {
  name: 'funcAppDeployment'
  params: {
    location: location
    packageUrl: funcAppPackageUrl
    //hubVnetId: hubVirtualNetworkModule.outputs.vnetRef
    //spokeVnetId: spokeVirtualNetworkModule.outputs.vnetRef
    vnetIntegrationSubnetId: spokeVirtualNetworkModule.outputs.subnetRefs[4].id
    //privateEndpointSubnetId: spokeVirtualNetworkModule.outputs.subnetRefs[3].id
    planSku: 'ElasticPremium'
    planSkuCode: 'EP1'
    planKind: 'elastic'
    suffix: suffix
    tags: tags
  }
} */

module funcAppModule './modules/funcapp.bicep' = {
  name: 'funcAppDeployment'
  params: {
    location: location
    vnetIntegrationSubnetId: spokeVirtualNetworkModule.outputs.vnet.subnetRefs[4].id
    apimSubnetId: hubVirtualNetworkModule.outputs.vnet.subnetRefs[4].id
    planSku: 'ElasticPremium'
    planSkuCode: 'EP1'
    planKind: 'elastic'
    suffix: suffix
    apimManagedIdentityPrincipalId: apiManagementModule.outputs.apimManagedIdentityPrincipalId
    appId: functionAppId
    tags: tags
  }
}

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  location: 'global'
  tags: tags
  name: privateDomainName
  properties: {}
}

module apiManagementModule './modules/apim.bicep' = {
  dependsOn: [
    azMonitorModule
    azureFirewallModule
    privateDnsZone
  ]
  name: 'apimDeployment'
  params: {
    tags: tags
    location: location
    retentionInDays: 30
    workspaceId: azMonitorModule.outputs.workspaceId
    privateDnsZoneName: privateDnsZone.name
    hubVnetId: hubVirtualNetworkModule.outputs.vnet.vnetRef
    spokeVnetId: spokeVirtualNetworkModule.outputs.vnet.vnetRef
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
    subnetId: hubVirtualNetworkModule.outputs.vnet.subnetRefs[4].id
  }
}

/* module apiModule './modules/api.bicep' = {
  dependsOn: [
    apiManagementModule
  ]
  name: 'apiDeployment'
  params: {
    apimName: apiManagementModule.outputs.apimName
    apiName: 'todo-api'
    functionUri: funcAppModule.outputs.funcAppUrl
  }
} */

module applicationGatewayModule './modules/appgateway.bicep' = {
  dependsOn: [
    azMonitorModule
    privateDnsZone
  ]
  name: 'applicationGatewayDeployment'
  params: {
    suffix: suffix
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
    apimPrivateIpAddress: '10.1.0.200' //appGwyPrivateIpAddress
    gatewaySku: {
      name: 'WAF_v2'
      tier: 'WAF_v2'
      capacity: '1'
    }
    requestTimeOut: 180
    skuName: 'Standard'
    subnetId: hubVirtualNetworkModule.outputs.vnet.subnetRefs[0].id
  }
}

module networkSecurityGroupUpdateModule './modules/nsg.bicep' = {
  name: 'nsgUpdateDeployment'
  params: {
    location: location
    suffix: suffix
    appGatewayPublicIpAddress: applicationGatewayModule.outputs.appGwyPublicIpAddress
  }
}

module appGwyApiPublicDnsRecord 'modules/publicdns.bicep' = {
  scope: resourceGroup('external-dns-zones-rg')
  name: 'deployAppGwyPublicDnsRecord'
  params: {
    zoneName: domainName
    ipAddress: applicationGatewayModule.outputs.appGwyPublicIpAddress
    recordName: 'api'
  }
}

module appGwyApimPortalPublicDnsRecord 'modules/publicdns.bicep' = {
  scope: resourceGroup('external-dns-zones-rg')
  name: 'deployAppGwyApimPortalPublicDnsRecord'
  params: {
    zoneName: domainName
    ipAddress: applicationGatewayModule.outputs.appGwyPublicIpAddress
    recordName: 'portal'
  }
}

module appGwyApimManagementPublicDnsRecord 'modules/publicdns.bicep' = {
  scope: resourceGroup('external-dns-zones-rg')
  name: 'deployAppGwyApimManagementPublicDnsRecord'
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
output funcAppName string = funcAppModule.outputs.funcAppName
output funcAppUri string = funcAppModule.outputs.funcAppUrl
output apimName string = apiManagementModule.outputs.apimName
output apimManagedIdentity string = apiManagementModule.outputs.apimManagedIdentityPrincipalId
/* output apiName string = apiModule.outputs.apiName
output apiId string = apiModule.outputs.apiId */
