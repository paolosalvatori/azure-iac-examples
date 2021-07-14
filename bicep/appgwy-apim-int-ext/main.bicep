param apiHostName string
//param portalHostName string
param domainName string
param virtualNetworks array
param tags object
//param userObjectId string
param location string
param cert object
param rootCert object
//param customData string

var suffix = uniqueString(resourceGroup().id)
//var keyVaultName = 'kvlt-${suffix}'
var separatedAddressprefix = split(virtualNetworks[0].subnets[3].addressPrefix, '.')
var azFirewallPrivateIpAddress = '${separatedAddressprefix[0]}.${separatedAddressprefix[1]}.${separatedAddressprefix[2]}.4'

/* 
module keyVaultModule './modules/keyvault.bicep' = {
  name: 'keyVaultDeployment'
  params: {
    name: keyVaultName
    keyVaultUserObjectId: userObjectId
    location: location
    tenantId: subscription().tenantId
  }
}

resource keyVaultSecrets 'Microsoft.KeyVault/vaults/secrets@2021-04-01-preview' = [for secret in secrets: {
  parent: keyVaultModule
  name: '${keyVaultName}/${secret.CertName}'
  properties: {
    contentType: 'application/x-pkcs12'
    value: secret.CertValue
  }
}]
 */
/* resource userAssignedManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  dependsOn: keyVaultSecrets
  location: location
  name: 'scriptUserAssignedManagedIdentity'
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  dependsOn: [
    userAssignedManagedIdentity
  ]
  name: guid(resourceGroup().id, userAssignedManagedIdentity.name, subscription().subscriptionId)
  scope: resourceGroup()
  properties: {
    principalId: userAssignedManagedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: 'Reader'
  }
}

resource keyVaultName_add 'Microsoft.KeyVault/vaults/accessPolicies@2021-04-01-preview' = {
  dependsOn: [
    roleAssignment
  ]
  name: '${keyVaultName}/add'
  properties: {
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: userAssignedManagedIdentity.properties.principalId
        permissions: {
          certificates: [
            'get'
            'list'
            'create'
            'import'
            'getissuers'
            'listissuers'
            'update'
            'setissuers'
            'restore'
            'recover'
            'backup'
          ]
        }
      }
    ]
  }
} */

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

/* module linuxVmModule './modules/linuxvm.bicep' = {
  dependsOn: [
    bastionModule
  ]
  name: 'linuxVmDeployment'
  params: {
    customData: customData
    adminPassword: 'M1cr0soft1234567890'
    adminUserName: 'localadmin'
    location: location
    subnetId: hubVirtualNetworkModule.outputs.subnetRefs[2].id
    suffix: suffix
    vmSize: 'Standard_D2_v3'
  }
} */

module wimVmModule './modules/winvm.bicep' = {
  dependsOn: [
    bastionModule
  ]
  name: 'winVmDeployment'
  params: {
    windowsOSVersion: '2016-Datacenter'
    adminPassword: 'M1cr0soft1234567890'
    adminUserName: 'localadmin'
    location: location
    subnetId: hubVirtualNetworkModule.outputs.subnetRefs[2].id
    suffix: suffix
    vmSize: 'Standard_D2_v3'
  }
}

/* module appSvcModule './modules/appsvc.bicep' = {
  name: 'appSvcDeployment'
  params: {
    containerName: 'belstarr/go-web-api:v1.0'
    hubVnetId: hubVirtualNetworkModule.outputs.vnetRef
    spokeVnetId: spokeVirtualNetworkModule.outputs.vnetRef
    privateEndpointSubnetId: spokeVirtualNetworkModule.outputs.subnetRefs[3].id
    vnetIntegrationSubnetId: spokeVirtualNetworkModule.outputs.subnetRefs[2].id
    skuName: 'P3v2'
    tags: tags
  }
} */

module funcAppModule './modules/funcapp.bicep' = {
  name: 'funcAppModule'
  params: {
    location: location
    hubVnetId: hubVirtualNetworkModule.outputs.vnetRef
    spokeVnetId: spokeVirtualNetworkModule.outputs.vnetRef
    vnetIntegrationSubnetId: spokeVirtualNetworkModule.outputs.subnetRefs[4].id
    privateEndpointSubnetId: spokeVirtualNetworkModule.outputs.subnetRefs[3].id
    planSku: 'ElasticPremium'
    planSkuCode: 'EP1'
    planKind: 'elastic'
    suffix: suffix
    tags: tags
  }
}

/* module keyVaultCertUploadScriptModule './modules/script.bicep' = {
  dependsOn: [
    keyVaultName_add
  ]
  name: 'keyVaultCertDeployment'
  params: {
    userAssignedIdentity: userAssignedManagedIdentity.id
    certificateBase64String: secrets[0].CertValue
    certificatePassword: secrets[0].CertPassword
    keyVaultName: keyVaultModule.outputs.keyVaultName
    location: location
    certificateName: secrets[0].CertName
  }
} */

/* module apiManagementModule './modules/apim.bicep' = {
  dependsOn: [
    azureFirewallModule
  ]
  name: 'apimDeployment'
  params: {
    tags: tags
    location: location
    apimPrivateDnsZoneName: domainName
    hubVnetId: hubVirtualNetworkModule.outputs.vnetRef
    spokeVnetId: spokeVirtualNetworkModule.outputs.vnetRef
    webAppUrl: 'https://${funcAppModule.outputs.funcAppUrl}'
    apimSku: {
      name: 'Developer'
      capacity: 1
    }
    deployCertificates: false
    gatewayHostName: '${apiHostName}.${domainName}'
    //portalHostName: '${portalHostName}.${domainName}'
    apiCertificate: secrets[0].CertValue
    apiCertificatePassword: secrets[0].CertPassword
    //portalCertificatePassword: certPassword
    subnetId: hubVirtualNetworkModule.outputs.subnetRefs[1].id
    keyVaultName: keyVaultModule.outputs.keyVaultName
    keyVaultUri: keyVaultModule.outputs.keyVaultUri
  }
}
 */
module apiManagementModule './modules/apim.bicep' = {
  dependsOn: [
    azureFirewallModule
  ]
  name: 'apimDeployment'
  params: {
    tags: tags
    location: location
    apimPrivateDnsZoneName: domainName
    hubVnetId: hubVirtualNetworkModule.outputs.vnetRef
    spokeVnetId: spokeVirtualNetworkModule.outputs.vnetRef
    webAppUrl: 'https://${funcAppModule.outputs.funcAppUrl}'
    apimSku: {
      name: 'Developer'
      capacity: 1
    }
    deployCertificates: true
    gatewayHostName: '${apiHostName}.${domainName}'
    //portalHostName: '${portalHostName}.${domainName}'
    apiCertificate: cert.CertValue
    apiCertificatePassword: cert.CertPassword
    //portalCertificatePassword: certPassword
    subnetId: hubVirtualNetworkModule.outputs.subnetRefs[1].id
    //keyVaultName: keyVaultModule.outputs.keyVaultName
    //keyVaultUri: keyVaultModule.outputs.keyVaultUri
  }
}

/* resource existingKeyVault 'Microsoft.KeyVault/vaults@2021-04-01-preview' existing = {
  name: keyVaultName
  scope: resourceGroup()
} */

module applicationGatewayModule './modules/appgateway.bicep' = {
  name: 'applicationGatewayDeployment'
  params: {
    suffix: suffix
    apimGatewaySslCertPassword: cert.CertPassword
    //apimPortalSslCertPassword: certPassword
    apiHostName: '${apiHostName}.${domainName}'
    rootSslCert: rootCert.CertValue
    rootSslCertPassword: rootCert.CertPassword
    //portalHostName: '${portalHostName}.${domainName}'
    apimGatewaySslCert: cert.CertValue // existingKeyVault.getSecret('apimapi')
    //apimPortalSslCert: existingKeyVault.getSecret('apimportal')
    frontEndPort: 443
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

/* module mySqlServer './modules/mysql.bicep' = {
  name: 'mySqlDeployment'
  params: {
    administratorLogin: 'dbadmin'
    administratorLoginPassword: 'P@ssword123'
    location: location
    suffix: suffix
  }
} */

/* module mySqlFlexServer './modules/mysql-flex-server.bicep' = {
  name: 'mySqlFlexServer'
  params: {
    administratorLogin: 'dbadmin'
    administratorLoginPassword: 'P@ssword123'
    mySqlDatabaseName: 'todolist'
    backupRetentionDays: 7
    location: location
    suffix: suffix
    subnetArmResourceId: spokeVirtualNetworkModule.outputs.subnetRefs[1].id
    tags: tags
  }
}
 */
output appGwyName string = applicationGatewayModule.outputs.appGwyName
output appGwyId string = applicationGatewayModule.outputs.appGwyId
