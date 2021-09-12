param vmSku string = 'Standard_D2_v4'
param vmssSubnetId string
param appGatewayBePoolResourceId string
param sshPublicKey string
param vmssExtensionCustomScriptUri string
param forceScriptUpdate int
param storageAccountName string

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
var autoscaleName = '${prefix}-cpu-autoscale'
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

resource publicIP 'Microsoft.Network/publicIPAddresses@2020-06-01' = {
  name: publicIPAddressName
  location: location
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
    dnsSettings: {
      domainNameLabel: longprefix
    }
  }
}

resource vmss 'Microsoft.Compute/virtualMachineScaleSets@2020-06-01' = {
  name: vmssName
  location: location
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
    overprovision: true
    upgradePolicy: {
      automaticOSUpgradePolicy: {
        enableAutomaticOSUpgrade: false
      }
      mode: 'Manual'
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
      extensionProfile: {
        extensions: [
          {
            name: 'app-config'
            properties: {
              publisher: 'Microsoft.Azure.Extensions'
              forceUpdateTag: string(forceScriptUpdate)
              type: 'CustomScript'
              typeHandlerVersion: '2.1'
              autoUpgradeMinorVersion: true
              settings: {
                timestamp: int(forceScriptUpdate)
              }
              protectedSettings: {
                managedIdentity: {}
                fileUris: [
                  '${vmssExtensionCustomScriptUri}/install.sh'
                  '${vmssExtensionCustomScriptUri}/main'
                ]
                commandToExecute: 'sh ./install.sh'
              }
            }
          }
          /* {
            name: 'healthExtension'
            properties: {
              autoUpgradeMinorVersion: true
              enableAutomaticUpgrade: true
              forceUpdateTag: 'a'
              type: 'ApplicationHealthLinux'
              typeHandlerVersion: '1.0'
              publisher: 'Microsoft.ManagedServices'
              settings: {
                protocol: 'http'
                port: 80
                requestPath: '/'
              }
            }
          } */
        ]
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

resource autoScaleSettings 'microsoft.insights/autoscalesettings@2015-04-01' = {
  name: autoscaleName
  location: location
  properties: {
    name: autoscaleName
    targetResourceUri: vmss.id
    enabled: true
    profiles: [
      {
        name: 'Profile1'
        capacity: {
          minimum: '1'
          maximum: '10'
          default: '1'
        }
        rules: [
          {
            metricTrigger: {
              metricName: 'Percentage CPU'
              metricNamespace: ''
              metricResourceUri: vmss.id
              timeGrain: 'PT1M'
              timeWindow: 'PT5M'
              timeAggregation: 'Average'
              operator: 'GreaterThan'
              threshold: 50
              statistic: 'Average'
            }
            scaleAction: {
              direction: 'Increase'
              type: 'ChangeCount'
              value: '1'
              cooldown: 'PT5M'
            }
          }
          {
            metricTrigger: {
              metricName: 'Percentage CPU'
              metricNamespace: ''
              metricResourceUri: vmss.id
              timeGrain: 'PT1M'
              timeWindow: 'PT5M'
              timeAggregation: 'Average'
              operator: 'LessThan'
              threshold: 30
              statistic: 'Average'
            }
            scaleAction: {
              direction: 'Decrease'
              type: 'ChangeCount'
              value: '1'
              cooldown: 'PT5M'
            }
          }
        ]
      }
    ]
  }
}
