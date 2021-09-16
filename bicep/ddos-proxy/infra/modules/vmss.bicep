param vmSku string = 'Standard_D2_v4'
param vmssSubnetId string
param appGatewayResourceId string
param appGatewayBePoolResourceId string
param extensionName string = 'LinuxCustomScriptExtension'
param forceUpdateTag int
param vmssExtensionCustomScriptUri string
param commandToExecute string = 'sh ./install.sh'
param sshPublicKey string
param tags object
param storageAccountName string
// param ilbBackendPoolResourceId string
param albBackendPoolResourceId string

@description('The Ubuntu version for the VM. This will pick a fully patched image of this given Ubuntu version.')
@allowed([
  '12.04.5-LTS'
  '14.04.5-LTS'
  '16.04.0-LTS'
  '18.04-LTS'
])
param ubuntuOSVersion string = '18.04-LTS'

@minValue(1)
@maxValue(100)
param instanceCount int
param adminUsername string

@secure()
param adminPassword string
param location string = resourceGroup().location

var prefix = toLower(uniqueString(resourceGroup().id))
var vmssName = '${prefix}-vmss'
var longprefix = toLower(vmssName)
var publicIPAddressName = '${prefix}-pip'
var autoscaleName = '${prefix}-apgwy-autoscale'
var nicname = '${prefix}-nic'
var ipConfigName = '${prefix}ipconfig'
var imageReference = osType
var osType = {
  publisher: 'Canonical'
  offer: 'UbuntuServer'
  sku: ubuntuOSVersion
  version: 'latest'
}

var dataContributorRoleId = resourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')

resource vmss 'Microsoft.Compute/virtualMachineScaleSets@2020-06-01' = {
  name: vmssName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: vmSku
    tier: 'Standard'
    capacity: instanceCount
  }
  zones: [
    '1'
    '2'
    '3'
  ]
  properties: {
    overprovision: false
    upgradePolicy: {
      automaticOSUpgradePolicy: {
        enableAutomaticOSUpgrade: false
      }
      mode: 'Automatic'
      rollingUpgradePolicy: {
        maxBatchInstancePercent: 10
      }
    }
    doNotRunExtensionsOnOverprovisionedVMs: false
    zoneBalance: true
    scaleInPolicy: {
      rules: [
        'OldestVM'
      ]
    }
    virtualMachineProfile: {
      storageProfile: {
        osDisk: {
          createOption: 'FromImage'
          caching: 'ReadWrite'
        }
        imageReference: imageReference
      }
      osProfile: {
        computerNamePrefix: prefix
        adminUsername: adminUsername
        adminPassword: adminPassword
        linuxConfiguration: {
          disablePasswordAuthentication: true
          provisionVMAgent: true
          ssh: {
            publicKeys: [
              {
                keyData: sshPublicKey
                path: '/home/${adminUsername}/.ssh/authorized_keys'
              }
            ]
          }
        }
      }
      extensionProfile: {
      }
      networkProfile: {
        networkInterfaceConfigurations: [
          {
            name: nicname
            properties: {
              primary: true
              ipConfigurations: [
                {
                  name: ipConfigName
                  properties: {
                    subnet: {
                      id: vmssSubnetId
                    }
                    applicationGatewayBackendAddressPools: [
                      {
                        id: appGatewayBePoolResourceId
                      }
                    ]
                    loadBalancerBackendAddressPools: [
                      {
                        id: albBackendPoolResourceId
                      }
                    ]
                  }
                }
              ]
            }
          }
        ]
      }
    }
  }
}

resource existingStorage 'Microsoft.Storage/storageAccounts@2021-04-01' existing = {
  name: storageAccountName
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2021-04-01-preview' = {
  name: guid(resourceGroup().id, vmss.name, 'StorageDataContributor')
  scope: existingStorage
  properties: {
    principalId: vmss.identity.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: dataContributorRoleId
  }
}

output vmssName string = vmss.name
output vmssResourceId string = vmss.id
