param prefix string
param pfxCertificate string
param pfxCertificatePassword string
param adminUserObjectId string
param containerPort string
param containerImageName string
param dnsZoneName string
param hostName string
param appServicePlanSku string

var namingPrefix = '${prefix}-${uniqueString(resourceGroup().id)}'

resource userAssignedManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  location: resourceGroup().location
  name: 'appGwyUserManagedId'
}

module appService './modules/appService.bicep' = {
  name: 'deployAppService'
  params: {
    containerPort: containerPort
    prefix: namingPrefix
    containerImageName: containerImageName
    sku: appServicePlanSku
  }
}

module keyVault './modules/keyVault.bicep' = {
  name: 'deployKeyVault'
  params: {
    adminUserObjectId: adminUserObjectId
    certificateData: pfxCertificate
    userAssignedManagedIdentity: userAssignedManagedIdentity
    prefix: namingPrefix
  }
}

module appGatewayModule './modules/appGateway.bicep' = {
  name: 'appGwyDeploy'
  params: {
    userAssignedManagedIdentityId: userAssignedManagedIdentity.id
    prefix: namingPrefix
    gatewaySku: 'WAF_v2'
    webAppHostName: appService.outputs.webAppHostName
    pfxCertSecretId: keyVault.outputs.secretUri
    pfxCertPassword: pfxCertificatePassword
    probePath: '/blockchain'
    frontEndHostName: '${hostName}.${dnsZoneName}'
  }
}

output AppGatewayFrontEndIpAddress string = appGatewayModule.outputs.AppGatewayFrontEndIpAddress
