param domainName string
param virtualNetworks array
param tags object
param location string
param cert object
param rootCert object
param winVmPassword string
param funcAppPackageUrl string

var suffix = uniqueString(resourceGroup().id)
var azSeparatedAddressprefix = split(virtualNetworks[0].subnets[3].addressPrefix, '.')
var appGwySeparatedAddressprefix = split(virtualNetworks[0].subnets[0].addressPrefix, '.')
var azFirewallPrivateIpAddress = '${azSeparatedAddressprefix[0]}.${azSeparatedAddressprefix[1]}.${azSeparatedAddressprefix[2]}.4'
var appGwyPrivateIpAddress = '${appGwySeparatedAddressprefix[0]}.${appGwySeparatedAddressprefix[1]}.${appGwySeparatedAddressprefix[2]}.200'

module azMonitorModule './modules/azmon.bicep' = {
  name: 'azureMonitorDeployment'
  params: {
    suffix: suffix
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

module hubVirtualNetworkModule './modules/vnets.bicep' = {
  name: 'hubVNetDeployment'
  dependsOn: [
    userDefinedRouteModule
  ]
  params: {
    location: location
    suffix: suffix
    tags: tags
    vNet: virtualNetworks[0]
  }
}

module spokeVirtualNetworkModule './modules/vnets.bicep' = {
  name: 'spokeVNetDeployment'
  dependsOn: [
    userDefinedRouteModule
  ]
  params: {
    location: location
    suffix: suffix
    tags: tags
    vNet: virtualNetworks[1]
  }
}

module virtualNetworkPeeringModule './modules/peerings.bicep' = {
  dependsOn: [
    hubVirtualNetworkModule
    spokeVirtualNetworkModule
  ]
  name: 'vNetPeeringDeployment'
  params: {
    suffix: suffix
    vNets: virtualNetworks
  }
}

module userDefinedRouteModule './modules/udr.bicep' = {
  name: 'udrDeployment'
  params: {
    suffix: suffix
    azureFirewallPrivateIpAddress: azFirewallPrivateIpAddress
  }
}

module azureFirewallModule './modules/azfirewall.bicep' = {
  name: 'azureFirewallDeployment'
  params: {
    suffix: suffix
    firewallSubnetRef: hubVirtualNetworkModule.outputs.subnetRefs[3].id
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
    subnetId: hubVirtualNetworkModule.outputs.subnetRefs[4].id
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
    subnetId: hubVirtualNetworkModule.outputs.subnetRefs[2].id
    suffix: suffix
    vmSize: 'Standard_D2_v3'
  }
}

module funcAppModule './modules/funcapp1.bicep' = {
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
}

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  location: 'global'
  tags: tags
  name: domainName
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
    hubVnetId: hubVirtualNetworkModule.outputs.vnetRef
    spokeVnetId: spokeVirtualNetworkModule.outputs.vnetRef
    apimSku: {
      name: 'Developer'
      capacity: 1
    }
    deployCertificates: true
    gatewayHostName: 'apim.internal.${domainName}'
    apiCertificate: cert.CertValue
    apiCertificatePassword: cert.CertPassword
    subnetId: hubVirtualNetworkModule.outputs.subnetRefs[1].id
  }
}

module apiModule './modules/api.bicep' = {
  dependsOn: [
    apiManagementModule
  ]
  name: 'apiDeployment'
  params: {
    apimName: apiManagementModule.outputs.apimName
    apiName: 'todo-api'
    functionUri: funcAppModule.outputs.funcAppUrl
  }
}

module applicationGatewayModule './modules/appgateway.bicep' = {
  dependsOn: [
    azMonitorModule
    privateDnsZone
  ]
  name: 'applicationGatewayDeployment'
  params: {
    suffix: suffix
    privateDnsZoneName: domainName
    workspaceId: azMonitorModule.outputs.workspaceId
    apimGatewaySslCertPassword: cert.CertPassword
    externalApiHostName: 'api.${domainName}'
    internalApiHostName: 'api.internal.${domainName}'
    apimHostName: 'apim.internal.${domainName}'
    rootSslCert: rootCert.CertValue
    apimGatewaySslCert: cert.CertValue
    frontEndPort: 443
    apimPrivateIpAddress: appGwyPrivateIpAddress
    gatewaySku: {
      name: 'WAF_v2'
      tier: 'WAF_v2'
      capacity: '1'
    }
    requestTimeOut: 180
    skuName: 'Standard'
    subnetId: hubVirtualNetworkModule.outputs.subnetRefs[0].id
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

module appGwyPublicDnsRecord 'modules/publicdns.bicep' = {
  scope: resourceGroup('external-dns-zones-rg')
  name: 'deployAppGwyPublicDnsRecord'
  params: {
    zoneName: domainName
    ipAddress: applicationGatewayModule.outputs.appGwyPublicIpAddress
    recordName: 'api'
  }
}

output appGwyName string = applicationGatewayModule.outputs.appGwyName
output appGwyId string = applicationGatewayModule.outputs.appGwyId
output appGwyFqdn string = applicationGatewayModule.outputs.appGwyPublicDnsName
output appGwyPublicIpAddress string = applicationGatewayModule.outputs.appGwyPublicIpAddress
output apimPrivateIpAddress string = apiManagementModule.outputs.apimPrivateIpAddress
