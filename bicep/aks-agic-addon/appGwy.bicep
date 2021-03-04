param applicationGatewaySKU string {
  allowed: [
    'Standard_v2'
    'WAF_v2'
  ]
  default: 'WAF_v2'
}
param applicationGatewaySubnetId string
param tags object
param suffix string

var publicIpName = 'applicationGateway-vip-${suffix}'
var applicationGatewayName = 'applicationGateway-${suffix}'
var uamIdName = 'applicationGatewayUmId'
var uamId = resourceId('Microsoft.ManagedIdentity/userAssignedIdentities', uamIdName)
var webApplicationFirewallConfiguration = {
  enabled: 'true'
  firewallMode: 'Detection'
}

resource applicationGatewayPublicIp 'Microsoft.Network/publicIPAddresses@2018-08-01' = {
  name: publicIpName
  location: resourceGroup().location
  sku: {
    name: 'Standard'
  }
  tags: tags
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource userDefinedManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  location: resourceGroup().location
  name: uamIdName
  tags: tags
}

resource applicationGateway 'Microsoft.Network/applicationGateways@2020-06-01' = {
  name: applicationGatewayName
  location: resourceGroup().location
  tags: tags
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${uamId}': {}
    }
  }
  properties: {
    sku: {
      name: applicationGatewaySKU
      tier: applicationGatewaySKU
      capacity: 2
    }
    gatewayIPConfigurations: [
      {
        name: 'appGatewayIpConfig'
        properties: {
          subnet: {
            id: applicationGatewaySubnetId
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'appGatewayFrontendIP'
        properties: {
          publicIPAddress: {
            id: applicationGatewayPublicIp.id
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'appGatewayFrontendHttpPort'
        properties: {
          port: 80
        }
      }
      {
        name: 'appGatewayFrontendHttpsPort'
        properties: {
          port: 443
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'appGatewayBackendPool'
        properties: {
          backendAddresses: []
        }
      }
    ]
    httpListeners: [
      {
        name: 'appGatewayHttpListener'
        properties: {
          protocol: 'Http'
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', applicationGatewayName, 'appGatewayFrontendHttpPort')
          }
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', applicationGatewayName, 'appGatewayFrontendIp')
          }
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'appGatewayBackendHttpSettings'
        properties: {
          port: 80
          protocol: 'Http'
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'rule1'
        properties: {
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', applicationGatewayName, 'appGatewayHttpListener')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', applicationGatewayName, 'appGatewayBackendPool')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', applicationGatewayName, 'appGatewayBackendHttpSettings')
          }
        }
      }
    ]
    webApplicationFirewallConfiguration: ((applicationGatewaySKU == 'WAF_v2') ? webApplicationFirewallConfiguration : json('null'))
  }
}

output applicationGatewayId string = applicationGateway.id
output applicationGatewayName string = applicationGateway.name
output applicationGatewayPublicIpResourceId string = applicationGatewayPublicIp.id
output managedIdentityClientId string = reference(uamId).clientId
output managedIdentityPrincipalId string = reference(uamId).principalId
output managedIdentityId string = uamId
