param firewallSubnetRef string
param sourceAddressRangePrefix array
param suffix string

var publicIpName = 'azfw-pip-${suffix}'
var firewallName = 'azfw-${suffix}'

resource publicIP 'Microsoft.Network/publicIPAddresses@2017-11-01' = {
  name: publicIpName
  location: resourceGroup().location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
}

resource azFirewall 'Microsoft.Network/azureFirewalls@2018-11-01' = {
  name: firewallName
  location: resourceGroup().location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          subnet: {
            id: firewallSubnetRef
          }
          publicIPAddress: {
            id: publicIP.id
          }
        }
      }
    ]
    applicationRuleCollections: [
      {
        name: 'aks'
        properties: {
          priority: 100
          action: {
            type: 'Allow'
          }
          rules: [
            {
              name: 'allow-aks'
              sourceAddresses: sourceAddressRangePrefix
              protocols: [
                {
                  protocolType: 'Http'
                  port: 80
                }
                {
                  protocolType: 'Https'
                  port: 443
                }
              ]
              targetFqdns: [
                '*.azmk8s.io'
                '*auth.docker.io'
                '*cloudflare.docker.io'
                '*cloudflare.docker.com'
                '*registry-1.docker.io'
              ]
            }
          ]
        }
      }
      {
        name: 'oss'
        properties: {
          priority: 200
          action: {
            type: 'Allow'
          }
          rules: [
            {
              name: 'allow-oss'
              sourceAddresses: sourceAddressRangePrefix
              protocols: [
                {
                  protocolType: 'Http'
                  port: 80
                }
                {
                  protocolType: 'Https'
                  port: 443
                }
              ]
              targetFqdns: [
                'download.opensuse.org'
                'login.microsoftonline.com'
                '*.ubuntu.com'
                'dc.services.visualstudio.com'
                '*.opinsights.azure.com'
                'github.com'
                '*.github.com'
                'raw.githubusercontent.com'
                '*.ubuntu.com'
                'api.snapcraft.io'
                'download.opensuse.org'
              ]
            }
          ]
        }
      }
      {
        name: 'azure'
        properties: {
          priority: 300
          action: {
            type: 'Allow'
          }
          rules: [
            {
              name: 'allow-sites'
              sourceAddresses: sourceAddressRangePrefix
              protocols: [
                {
                  protocolType: 'Http'
                  port: 80
                }
                {
                  protocolType: 'Https'
                  port: 443
                }
              ]
              targetFqdns: [
                '*azurecr.io'
                '*blob.core.windows.net'
                '*.trafficmanager.net'
                '*.azureedge.net'
                '*.microsoft.com'
                '*.core.windows.net'
                'aka.ms'
                '*.azure-automation.net'
                '*.azure.com'
              ]
            }
          ]
        }
      }
    ]
    networkRuleCollections: [
      {
        name: 'netRulesCollection'
        properties: {
          priority: 100
          action: {
            type: 'Allow'
          }
          rules: [
            {
              name: 'allow-ssh-https'
              sourceAddresses: sourceAddressRangePrefix
              destinationAddresses: union(sourceAddressRangePrefix, array('*'))
              destinationPorts: [
                '22'
                '443'
              ]
              protocols: [
                'TCP'
              ]
            }
          ]
        }
      }
    ]
  }
}

output firewallPrivateIp string = azFirewall.properties.ipConfigurations[0].properties.privateIPAddress
output firewallPublicIp string = publicIP.properties.ipAddress
