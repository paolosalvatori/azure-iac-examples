@description('location to deploy the storage account')
param location string
param firewallName string
param firewallPublicIpName string
param firewallSubnetRef string
param workspaceId string

resource publicIP 'Microsoft.Network/publicIPAddresses@2021-05-01' = {
  name: firewallPublicIpName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
}

resource firewall 'Microsoft.Network/azureFirewalls@2021-03-01' = {
  name: firewallName
  location: location
  properties: {
    sku: {
      name: 'AZFW_VNet'
      tier: 'Standard'
    }
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
/*     natRuleCollections: []
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
              sourceAddresses: sourceAddresses
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
              sourceAddresses: sourceAddresses
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
                '*.ubuntu.com'
                'github.com'
                'gcr.io'
                '*.github.com'
                'raw.githubusercontent.com'
                '*.ubuntu.com'
                'api.snapcraft.io'
                'download.opensuse.org'
                'storage.googleapis.com'
                'security.ubuntu.com'
                'azure.archive.ubuntu.com'
                'changelogs.ubuntu.com'
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
              sourceAddresses: sourceAddresses
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
                'dc.services.visualstudio.com'
                '*.opinsights.azure.com'
                'login.microsoftonline.com'
                '*azurecr.io'
                '*.blob.${environment().suffixes.storage}'
                '*.trafficmanager.net'
                '*.azureedge.net'
                '*.microsoft.com'
                '*${environment().suffixes.storage}' // '*.core.windows.net'
                'aka.ms'
                '*.azure-automation.net'
                '*.azure.com'
                'gov-prod-policy-data.trafficmanager.net'
                '*.gk.${location}.azmk8s.io'
                '*.monitoring.azure.com'
                '*.oms.opinsights.azure.com'
                '*.ods.opinsights.azure.com'
                '*.microsoftonline.com'
                '*.data.mcr.microsoft.com'
                '*.cdn.mscr.io'
                'mcr.microsoft.com'
                'management.azure.com'
                'packages.microsoft.com'
                '*.dp.kubernetesconfiguration.azure.com'
                'azurearcfork8s.azurecr.io'
                '*.data.azurecr.io'
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
              name: 'allow-outbound-http-https-internet'
              sourceAddresses: sourceAddresses
              destinationAddresses: [
                '*'
              ]
              destinationPorts: [
                '80'
                '443'
                '53'
                '123'
                '22'
              ]
              protocols: [
                'TCP'
                'UDP'
                'ICMP'
              ]
            }
          ]
        }
      }
    ] */
  }
}

resource firewall_diagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'firewall-diagnostics'
  scope: firewall
  properties: {
    workspaceId: workspaceId
    logs: [
      {
        category: 'AzureFirewallApplicationRule'
        enabled: true
      }
      {
        category: 'AzureFirewallNetworkRule'
        enabled: true
      }
      {
        category: 'AzureFirewallDnsProxy'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

output firewallPublicIpAddress string = publicIP.properties.ipAddress
