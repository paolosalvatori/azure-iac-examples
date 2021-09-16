param adminUsername string
param adminPassword string
param vmssInstanceCount int
param pfxCert string
param pfxCertPassword string
param appGwyHostName string
param sshPublicKey string
param vmssCustomScriptUri string
param dnsResourceGroupName string = 'external-dns-zones-rg'
param dnsZoneName string = 'kainiindustries.net'
param dnsARecordName string = 'myapp'
param forceUpdateTag int
param storageAccountName string
param domainNameLabel string = 'ddos-proxy'
param albBackendPoolName string = 'alb-backend-pool'
param tags object = {
  costcentre: '1234567890'
  environment: 'dev'
}

var prefix = uniqueString(resourceGroup().id)
var vnetName = '${prefix}-vnet'
var natGatewayName = '${prefix}-natgw'
var natGatewayPublicIPAddressName = '${prefix}-natgw-pip'
var appGatewayNsgName = '${prefix}-appgwy-nsg'
var loadBalancerName = '${prefix}-alb'
var albPublicIpAddressName = '${prefix}-vmss-alb-pip'

var subnets = [
  {
    name: 'AppGatewaySubnet'
    properties: {
      addressPrefix: '10.0.0.0/24'
      networkSecurityGroup: {
        id: nsgModule.outputs.nsgResourceIds[0]
      }
    }
  }
  {
    name: 'VmssSubnet'
    properties: {
      addressPrefix: '10.0.1.0/24'
      natGateway: {
        id: natGatewayMod.outputs.natGatewayResourceId
      }
    }
  }
  {
    name: 'AzureBastionSubnet'
    properties: {
      addressPrefix: '10.0.2.0/24'
    }
  }
]

module nsgModule './modules/nsg.bicep' = {
  name: 'nsgDeployment'
  params: {
    appGatewayPublicIpAddress: '1.1.1.1'
    appGatewayNsgName: appGatewayNsgName
    tags: tags
  }
}

module natGatewayMod './modules/natGateway.bicep' = {
  name: 'natGatewayDeployment'
  params: {
    natGatewayName: natGatewayName
    publicIpAddressName: natGatewayPublicIPAddressName
    domainNameLabel: '${domainNameLabel}-natgw'
    tags: tags
  }
}

module vnetMod './modules/vnet.bicep' = {
  name: 'vnetDeployment'
  params: {
    vnetName: vnetName
    subnetArray: subnets
    vnetAddressPrefixes: [
      '10.0.0.0/16'
    ]
  }
}

module bastionMod './modules/bastion.bicep' = {
  name: 'bastionDeployment'
  params: {
    subnetId: vnetMod.outputs.subnetList[2].id
  }
}

module appGwyMod './modules/appGateway.bicep' = {
  name: 'appGwyDeployment'
  params: {
    probePath: '/'
    gatewaySku: 'WAF_v2'
    pfxCert: pfxCert
    pfxCertPassword: pfxCertPassword
    frontEndHostName: appGwyHostName
    subnetId: vnetMod.outputs.subnetList[0].id
    tags: tags
  }
}

module nsgModuleUpdate './modules/nsg.bicep' = {
  name: 'appGwyNsgUpdateDeployment'
  params: {
    appGatewayPublicIpAddress: appGwyMod.outputs.appGatewayFrontEndIpAddress
    appGatewayNsgName: appGatewayNsgName
    tags: tags
  }
}

module publicLoadBalancer 'modules/alb.bicep' = {
  name: 'vmssLoadBalancerDeployment'
  params: {
    backendPoolName: albBackendPoolName
    domainNameLabel: '${domainNameLabel}-alb'
    loadBalancerName: loadBalancerName
    tags: tags
    vnetResourceId: vnetMod.outputs.vnetResourceId
    publicIpAddressName: albPublicIpAddressName
  }
}

module vmssMod './modules/vmss.bicep' = {
  name: 'vmssDeployment'
  params: {
    albBackendPoolResourceId: publicLoadBalancer.outputs.albBackendPoolResourceId
    sshPublicKey: sshPublicKey
    forceUpdateTag: forceUpdateTag
    commandToExecute: 'sh ./install.sh'
    storageAccountName: storageAccountName
    appGatewayResourceId: appGwyMod.outputs.appGatewayResourceId
    vmssExtensionCustomScriptUri: vmssCustomScriptUri
    appGatewayBePoolResourceId: appGwyMod.outputs.appGatewayBeAddressPoolResourceId
    instanceCount: vmssInstanceCount
    vmssSubnetId: vnetMod.outputs.subnetList[1].id
    adminUsername: adminUsername
    adminPassword: adminPassword
    tags: tags
  }
}

module vmssCustomScriptExtensionMod './modules/scriptExtension.bicep' = {
  name: 'vmssCustomScriptExtensionDeployment'
  params: {
    forceUpdateTag: forceUpdateTag
    vmssExtensionCustomScriptUri: vmssCustomScriptUri
    commandToExecute: 'sh ./install.sh'
    extensionName: 'vmssNginxInstallScriptExtension'
    vmssName: vmssMod.outputs.vmssName
  }
}

/* module dnsRecord './modules/dns.bicep' = {
  scope: resourceGroup(dnsResourceGroupName)
  name: 'dnsRecordDeployment'
  params: {
    dnsZoneName: dnsZoneName
    recordName: dnsARecordName
    appGatewayIpAddress: appGwyMod.outputs.appGatewayFrontEndIpAddress
  }
} */
