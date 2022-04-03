param location string
param backendHostName string
param frontEndHostName string
param backendIpAddress string
param minCapacity int = 2
param maxCapacity int = 10
param frontendPort int = 443
param backendPort int
param pfxCertSecretId string
param userAssignedManagedIdentityResourceId string
param subnetId string

@allowed([
  'Standard_v2'
  'WAF_v2'
])
param gatewaySku string

var suffix = uniqueString(resourceGroup().id)
var publicIpName = 'pip-${suffix}'
var applicationGatewayName = 'appgwy-${suffix}'
var wafPolicyName = 'waf-poli-${suffix}'
var certName = 'app-ssl-cert'

resource publicIp 'Microsoft.Network/publicIPAddresses@2020-06-01' = {
  name: publicIpName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
  }
}

resource applicationGatewayWafPolicy 'Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies@2020-08-01' = {
  name: wafPolicyName
  location: location
  properties: {
    managedRules: {
      exclusions: []
      managedRuleSets: [
        {
          ruleSetType: 'OWASP'
          ruleSetVersion: '3.1'
        }
      ]
    }
    policySettings: {
      fileUploadLimitInMb: 20
      maxRequestBodySizeInKb: 128
      mode: 'Prevention'
      requestBodyCheck: true
      state: 'Enabled'
    }
  }
}

resource applicationGateway 'Microsoft.Network/applicationGateways@2020-06-01' = {
  name: applicationGatewayName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedManagedIdentityResourceId}': {}
    }
  }
  properties: {
    sku: {
      name: gatewaySku
      tier: gatewaySku
    }
    firewallPolicy: {
      id: applicationGatewayWafPolicy.id
    }
    autoscaleConfiguration: {
      minCapacity: minCapacity
      maxCapacity: maxCapacity
    }
    sslCertificates: [
      {
        name: certName
        properties: {
          keyVaultSecretId: pfxCertSecretId
        }
      }
    ]
    trustedRootCertificates: []
    gatewayIPConfigurations: [
      {
        name: 'ipConfig'
        properties: {
          subnet: {
            id: subnetId
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'frontendIp'
        properties: {
          publicIPAddress: {
            id: publicIp.id
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'frontendPort'
        properties: {
          port: frontendPort
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'backendPool'
        properties: {
          backendAddresses: [
            {
              ipAddress: backendIpAddress
            }
          ]
        }
      }
    ]
    probes: []
    backendHttpSettingsCollection: [
      {
        name: 'backendHttpsSettings'
        properties: {
          port: backendPort
          protocol: 'Https'
          pickHostNameFromBackendAddress: false
          hostName: backendHostName
        }
      }
    ]
    httpListeners: [
      {
        name: 'multiSiteListener'
        properties: {
          hostName: frontEndHostName
          requireServerNameIndication: true
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', applicationGatewayName, 'frontendIp')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', applicationGatewayName, 'frontendPort')
          }
          protocol: 'Https'
          sslCertificate: {
            id: resourceId('Microsoft.Network/applicationGateways/sslCertificates', applicationGatewayName, certName)
          }
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'https_rule'
        properties: {
          ruleType: 'Basic'
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', applicationGatewayName, 'multiSiteListener')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', applicationGatewayName, 'backendPool')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', applicationGatewayName, 'backendHttpsSettings')
          }
        }
      }
    ]
  }
}

output appGatewayFrontEndIpAddressId string = publicIp.id
output appGatewayFrontEndIpAddress string = publicIp.properties.ipAddress
