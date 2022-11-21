param location string
param adminGroupObjectID string
param tags object
param k8sVersion string = '1.25.2'
param vmSku string
param addressPrefix string
param subnets array
param sshPublicKey string
param userName string = 'localadmin'
param dnsPrefix string
param appGwyUamiName string = 'appgateway-uami'
param publicDnsZoneName string
param nginxBackendIpAddress string
param internalHostName string
param keyVaultName string
param publicDnsZoneResourceGroup string

@secure()
param nginxTlsCertSecretId string

@secure()
param tlsCertSecretId string

var suffix = uniqueString(resourceGroup().id)
var NetworkContributor = '4d97b98b-1d4f-4787-a291-c67834d212e7'

module appGwyUami './modules/user_assigned_mid.bicep' = {
  name: 'appGwyUami-module'
  params: {
    location: location
    name: appGwyUamiName
  }
}

module azMonitor 'modules/azmon.bicep' = {
  name: 'azmon-module'
  params: {
    location: location
    suffix: suffix
  }
}

module wks './modules/wks.bicep' = {
  name: 'wks-module'
  params: {
    suffix: suffix
    tags: tags
    location: location
    retentionInDays: 30
  }
}

resource kv 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}

// grant application gateway user managed identity keyvault access policy
module appgatewayKeyVaultPolicies 'modules/keyvaultAccessPolicy.bicep' = {
  name: 'module-keyvault-access-policy'
  params: {
    accessPolicies: [
      {
        permissions: {
          keys: [
            'get'
            'list'
          ]
          secrets: [
            'get'
            'list'
          ]
          certificates: [
            'get'
            'list'
          ]
        }
        tenantId: tenant().tenantId
        objectId: appGwyUami.outputs.principalId
      }
    ]
    keyVaultName: kv.name
  }
}

module vnet './modules/vnet.bicep' = {
  name: 'vnet-module'
  params: {
    suffix: suffix
    tags: tags
    addressPrefix: addressPrefix
    location: location
    subnets: subnets
  }
}

resource bastionPip 'Microsoft.Network/publicIPAddresses@2022-05-01' = {
  name: 'bastion-pip-${suffix}'
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
  }
}

resource bastion 'Microsoft.Network/bastionHosts@2022-05-01' = {
  name: 'bastion-${suffix}'
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ip-config'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: bastionPip.id
          }
          subnet: {
            id: vnet.outputs.subnets[4].id
          }
        }
      }
    ]
  }
}

module acr './modules/acr.bicep' = {
  name: 'acr-module'
  params: {
    location: location
    suffix: suffix
    tags: tags
  }
}

module aks './modules/aks.bicep' = {
  name: 'aks-module'
  dependsOn: [
    vnet
    wks
  ]
  params: {
    location: location
    suffix: suffix
    logAnalyticsWorkspaceId: wks.outputs.workspaceId
    aksAgentOsDiskSizeGB: 60
    aksDnsServiceIP: '10.100.0.10'
    aksDockerBridgeCIDR: '172.17.0.1/16'
    aksServiceCIDR: '10.100.0.0/16'
    aksDnsPrefix: dnsPrefix
    aksEnableRBAC: true
    aksMaxNodeCount: 10
    aksMinNodeCount: 1
    aksNodeCount: 2
    aksNodeVMSize: vmSku
    aksSystemSubnetId: vnet.outputs.subnets[0].id
    aksUserSubnetId: vnet.outputs.subnets[1].id
    k8sVersion: k8sVersion
    enableAutoScaling: true
    maxPods: 110
    networkPlugin: 'azure'
    enablePodSecurityPolicy: false
    tags: tags
    enablePrivateCluster: false
    linuxAdminUserName: userName
    sshPublicKey: sshPublicKey
    adminGroupObjectID: adminGroupObjectID
    addOns: {
      azureKeyvaultSecretsProvider: {
        enabled: true
        config: {
          enableSecretRotation: 'true'
          rotationPollInterval: '2m'
        }
      }
      openServiceMesh: {
        enabled: true
        config: {}
      }
      azurepolicy: {
        enabled: true
        config: {
          version: 'v2'
        }
      }
      omsagent: {
        enabled: true
        config: {
          logAnalyticsWorkspaceResourceID: wks.outputs.workspaceId
        }
      }
    }
  }
}

resource assign_NetworkContributor_to_kubelet 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name: guid(resourceGroup().id, aks.name, NetworkContributor)
  scope: resourceGroup()
  dependsOn: [
    aks
  ]
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', NetworkContributor)
    principalType: 'ServicePrincipal'
    principalId: aks.outputs.aksClusterManagedIdentityObjectId
  }
}

module applicationGatewayModule './modules/appgateway.bicep' = {
  dependsOn: [
    vnet
    appgatewayKeyVaultPolicies
  ]
  name: 'module-applicationGateway'
  params: {
    suffix: suffix
    location: location
    umidResourceId: appGwyUami.outputs.id
    nginxBackendIpAddress: nginxBackendIpAddress
    nginxTlsCertSecretId: nginxTlsCertSecretId
    tlsCertSecretId: tlsCertSecretId
    workspaceId: azMonitor.outputs.workspaceId
    frontEndPort: 443
    retentionInDays: 7
    externalHostName: 'httpbin.${publicDnsZoneName}'
    internalHostName: internalHostName
    gatewaySku: {
      name: 'WAF_v2'
      tier: 'WAF_v2'
      capacity: '1'
    }
    requestTimeOut: 180
    skuName: 'Standard'
    subnetId: vnet.outputs.subnets[5].id
  }
}

module appGwyApiPublicDnsRecord 'modules/publicDnsRecord.bicep' = {
  scope: resourceGroup(publicDnsZoneResourceGroup)
  name: 'module-appgwy-public-dns-record'
  params: {
    zoneName: publicDnsZoneName
    ipAddress: applicationGatewayModule.outputs.appGwyPublicIpAddress
    recordName: 'httpbin'
  }
}

output aksClusterName string = aks.outputs.aksClusterName
output aksClusterFqdn string = aks.outputs.aksControlPlaneFQDN
output aksClusterApiServerUri string = aks.outputs.aksApiServerUri
