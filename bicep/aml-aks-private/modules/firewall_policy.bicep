param location string
param sourceAddresses array
param firewallName string

var sourceAddressPrefixes = [for item in sourceAddresses: item.properties.addressPrefix]

resource fw 'Microsoft.Network/azureFirewalls@2021-05-01' existing = {
  name: firewallName
}

// create a new firewall policy
resource fw_policy 'Microsoft.Network/firewallPolicies@2020-05-01' = {
  name: 'fw-policy-1'
  location: location
}

// add application & network rules to the policy
resource fw_policy_rule_collection_group 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2020-05-01' = {
  name: 'rule-collection-group-1'
  parent: fw_policy
  properties: {
    priority: 100
    ruleCollections: [
      {
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        name: 'rule-colletion-1'
        priority: 200
        action: {
          type: 'Allow'
        }
        rules: [
          {
            name: 'allow-aks-outbound'
            ruleType: 'ApplicationRule'
            sourceAddresses: sourceAddressPrefixes
            protocols: [
              {
                port: 80
                protocolType: 'Http'
              }
              {
                port: 443
                protocolType: 'Https'
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
          {
            name: 'allow-oss-outbound'
            ruleType: 'ApplicationRule'
            sourceAddresses: sourceAddressPrefixes
            protocols: [
              {
                port: 80
                protocolType: 'Http'
              }
              {
                port: 443
                protocolType: 'Https'
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
          {
            name: 'allow-azure-outbound'
            ruleType: 'ApplicationRule'
            sourceAddresses: sourceAddressPrefixes
            protocols: [
              {
                port: 80
                protocolType: 'Http'
              }
              {
                port: 443
                protocolType: 'Https'
              }
            ]
            targetFqdns: [
              'dc.services.visualstudio.com'
              '*.opinsights.azure.com'
              'login.microsoftonline.com'
              '*azurecr.io'
              '*.blob.core.windows.net'
              '*.trafficmanager.net'
              '*.azureedge.net'
              '*.microsoft.com'
              '*.core.windows.net'
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
              'acs-mirror.azureedge.net'
              '*.cdn.mscr.io'
              'mcr.microsoft.com'
              'management.azure.com'
              'packages.microsoft.com'
              '*.dp.kubernetesconfiguration.azure.com'
              'azurearcfork8s.azurecr.io'
            ]
          }
        ]
      }
      {
        name: 'rule-collection-2'
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        priority: 100
        action: {
          type: 'Allow'
        }
        rules: [
          {
            ruleType: 'NetworkRule'
            name: 'allow-outbound-dns-time-ssh'
            sourceAddresses: sourceAddressPrefixes
            destinationAddresses: [
              '*'
            ]
            destinationPorts: [
              '53'
              '123'
              '22'
            ]
            ipProtocols: [
              'TCP'
              'UDP'
              'ICMP'
            ]
          }
        ]
      }
    ]
  }
}
