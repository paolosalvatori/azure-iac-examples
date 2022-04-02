param domainName string
param frontendPort int
param backendPort int
param dnsZoneResourceGroup string
param keyVaultName string
param frontEndHostName string
param storageContainerUri string
param scriptName string
param location string
param pfxCertSecretId string
param pfxCertThumbprint string
param winVmPassword string
param storageAccountName string

resource userAssignedManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  location: location
  name: 'kvMid'
}

module keyVaultAccessPolicy 'modules/keyVaultAccessPolicy.bicep' = {
  name: 'keyVaultAccessPolicyDeployment'
  params: {
    objectId: userAssignedManagedIdentity.properties.principalId
    keyVaultName: keyVaultName
  }
}

module networkSecurityGroupModule './modules/nsg.bicep' = {
  name: 'nsgDeployment'
  params: {
    location: location
  }
}

module vnetModule './modules/vnet.bicep' = {
  name: 'vnetDeployment'
  params: {
    location: location
  }
  dependsOn: [
    networkSecurityGroupModule
  ]
}

module bastionModule './modules/bastion.bicep' = {
  name: 'bastionDeployment'
  params: {
    location: location
    subnetId: vnetModule.outputs.subnetRefs[2].id
  }
}

module winVmModule './modules/winvm.bicep' = {
  name: 'winVmDeployment'
  params: {
    storageAccountName: storageAccountName
    computerName: 'win-vm-1'
    userAssignedManagedIdentityResourceId: userAssignedManagedIdentity.id
    userAssignedManagedIdentityPrincipalId: userAssignedManagedIdentity.properties.principalId
    pfxCertThumbprint: pfxCertThumbprint
    scriptUri: '${storageContainerUri}/${scriptName}'
    pfxCertSecretId: pfxCertSecretId
    domainName: frontEndHostName
    windowsOSVersion: '2016-Datacenter'
    adminPassword: winVmPassword
    adminUserName: 'localadmin'
    location: location
    subnetId: vnetModule.outputs.subnetRefs[1].id
    vmSize: 'Standard_D2_v3'
  }
}

module applicationGatewayModule './modules/appgateway.bicep' = {
  name: 'applicationGatewayDeployment'
  params: {
    userAssignedManagedIdentityResourceId: userAssignedManagedIdentity.id
    backendHostName: frontEndHostName
    backendPort: backendPort
    backendIpAddress: winVmModule.outputs.ipAddress
    frontEndHostName: frontEndHostName
    location: location
    pfxCertSecretId: pfxCertSecretId
    frontendPort: frontendPort
    subnetId: vnetModule.outputs.subnetRefs[0].id
    maxCapacity: 10
    minCapacity: 1
    gatewaySku: 'WAF_v2'
  }
}

module appGwyApiPublicDnsRecord 'modules/publicdns.bicep' = {
  scope: resourceGroup(dnsZoneResourceGroup)
  name: 'deployAppGwyPublicDnsRecord'
  params: {
    zoneName: domainName
    ipAddress: applicationGatewayModule.outputs.appGatewayFrontEndIpAddress
    recordName: 'api'
  }
}
