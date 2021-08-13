param suffix string
param skuName string = 'Standard'
param apimPrivateIpAddress string
param gatewaySku object = {
  name: 'WAF_v2'
  tier: 'WAF_v2'
  capacity: '1'
}

param privateDnsZoneName string
param workspaceId string
param retentionInDays int = 30
param subnetId string

@secure()
param apimGatewaySslCert string

@secure()
param apimGatewaySslCertPassword string

@secure()
param rootSslCert string
param frontEndPort int = 443
param internalFrontendPort int = 8080
param requestTimeOut int = 180
param externalApiHostName string
param internalApiHostName string
param apimHostName string

var pipName_var = 'appgwy-pip-${suffix}'
var appGwyName = 'appgwy-${suffix}'

resource pipName 'Microsoft.Network/publicIPAddresses@2021-02-01' = {
  name: pipName_var
  location: resourceGroup().location
  sku: {
    name: skuName
  }
  properties: {
    dnsSettings: {
      domainNameLabel: appGwyName
    }
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
    ipTags: []
  }
}

resource appGwy 'Microsoft.Network/applicationGateways@2021-02-01' = {
  name: appGwyName
  location: resourceGroup().location
  properties: {
    sku: gatewaySku
    trustedRootCertificates: [
      {
        name: 'root-cert'
        properties: {
          data: rootSslCert
        }
      }
    ]
    gatewayIPConfigurations: [
      {
        name: 'gateway-ip'
        properties: {
          subnet: {
            id: subnetId
          }
        }
      }
    ]
    sslCertificates: [
      {
        name: 'apim-gateway-cert'
        properties: {
          data: apimGatewaySslCert
          password: apimGatewaySslCertPassword
        }
      }
    ]
    sslProfiles: [
      {
        name: 'sslProfile1'
        properties: {
          clientAuthConfiguration: {
            verifyClientCertIssuerDN: true
          }
          trustedClientCertificates: [
            {
              id: resourceId('Microsoft.Network/applicationGateways/trustedClientCertificates', appGwyName, 'rootCACert')
            }
          ]
        }
      }
    ]
    authenticationCertificates: []
    frontendIPConfigurations: [
      {
        name: 'frontend'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: pipName.id
          }
        }
      }
      {
        name: 'internal-frontend'
        properties: {
          privateIPAllocationMethod: 'Static'
          privateIPAddress: apimPrivateIpAddress
          subnet: {
            id: subnetId
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'frontend-port'
        properties: {
          port: frontEndPort
        }
      }
      {
        name: 'internal-frontend-port'
        properties: {
          port: internalFrontendPort
        }
      }
    ]
    trustedClientCertificates: [
      {
        name: 'rootCACert'
        properties: {
          data: rootSslCert
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'apim-backend'
        properties: {
          backendAddresses: [
            {
              fqdn: apimHostName
            }
          ]
        }
      }
      {
        name: 'sinkpool'
        properties: {
          backendAddresses: []
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'apim-gateway-poolsetting'
        properties: {
          port: frontEndPort
          protocol: 'Https'
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: false
          hostName: apimHostName
          requestTimeout: requestTimeOut
          trustedRootCertificates: [
            {
              id: resourceId('Microsoft.Network/applicationGateways/trustedRootCertificates', appGwyName, 'root-cert')
            }
          ]
          probe: {
            id: resourceId('Microsoft.Network/applicationGateways/probes', appGwyName, 'apim-gateway-probe')
          }
        }
      }
    ]
    httpListeners: [
      {
        name: 'apim-gateway-listener'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', appGwyName, 'frontend')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', appGwyName, 'frontend-port')
          }
          protocol: 'Https'
          sslCertificate: {
            id: resourceId('Microsoft.Network/applicationGateways/sslCertificates', appGwyName, 'apim-gateway-cert')
          }
          sslProfile: {
            id: resourceId('Microsoft.Network/applicationGateways/sslProfiles', appGwyName, 'sslProfile1')
          }
          hostName: externalApiHostName
          requireServerNameIndication: true
          customErrorConfigurations: []
        }
      }
      {
        name: 'internal-apim-gateway-listener'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', appGwyName, 'internal-frontend')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', appGwyName, 'internal-frontend-port')
          }
          protocol: 'Https'
          sslCertificate: {
            id: resourceId('Microsoft.Network/applicationGateways/sslCertificates', appGwyName, 'apim-gateway-cert')
          }
          hostName: internalApiHostName
          requireServerNameIndication: true
          customErrorConfigurations: []
        }
      }
    ]
    urlPathMaps: [
      {
        name: 'external-urlpathmapconfig'
        properties: {
          defaultBackendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', appGwyName, 'apim-backend')
          }
          defaultBackendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', appGwyName, 'apim-gateway-poolsetting')
          }
          pathRules: [
            {
              name: 'external'
              properties: {
                paths: [
                  '/external/*'
                ]
                backendAddressPool: {
                  id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', appGwyName, 'apim-backend')
                }
                backendHttpSettings: {
                  id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', appGwyName, 'apim-gateway-poolsetting')
                }
              }
            }
          ]
        }
      }
      {
        name: 'internal-urlpathmapconfig'
        properties: {
          defaultBackendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', appGwyName, 'apim-backend')
          }
          defaultBackendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', appGwyName, 'apim-gateway-poolsetting')
          }
          pathRules: [
            {
              name: 'internal'
              properties: {
                paths: [
                  '/internal/*'
                ]
                backendAddressPool: {
                  id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', appGwyName, 'apim-backend')
                }
                backendHttpSettings: {
                  id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', appGwyName, 'apim-gateway-poolsetting')
                }
              }
            }
          ]
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'apim-gateway-external-rule'
        properties: {
          ruleType: 'PathBasedRouting'
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', appGwyName, 'apim-gateway-listener')
          }
          urlPathMap: {
            id: resourceId('Microsoft.Network/applicationGateways/urlPathMaps', appGwyName, 'external-urlpathmapconfig')
          }
        }
      }
      {
        name: 'apim-gateway-internal-rule'
        properties: {
          ruleType: 'PathBasedRouting'
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', appGwyName, 'internal-apim-gateway-listener')
          }
          urlPathMap: {
            id: resourceId('Microsoft.Network/applicationGateways/urlPathMaps', appGwyName, 'internal-urlpathmapconfig')
          }
        }
      }
    ]
    probes: [
      {
        name: 'apim-gateway-probe'
        properties: {
          protocol: 'Https'
          host: apimHostName
          path: '/status-0123456789abcdef'
          interval: 30
          timeout: 120
          unhealthyThreshold: 8
          pickHostNameFromBackendHttpSettings: false
          minServers: 0
          match: {}
        }
      }
    ]
    rewriteRuleSets: []
    redirectConfigurations: []
    webApplicationFirewallConfiguration: {
      enabled: true
      firewallMode: 'Prevention'
      ruleSetType: 'OWASP'
      ruleSetVersion: '3.0'
      disabledRuleGroups: []
      exclusions: []
      requestBodyCheck: true
      maxRequestBodySizeInKb: 128
      fileUploadLimitInMb: 100
    }
    customErrorConfigurations: []
  }
}

resource appGwyPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: privateDnsZoneName
}

resource appGwyDnsRecord 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  parent: appGwyPrivateDnsZone
  name: internalApiHostName
  properties: {
    aRecords: [
      {
        ipv4Address: appGwy.properties.frontendIPConfigurations[1].properties.privateIPAddress
      }
    ]
    ttl: 3600
  }
}

resource appGwyDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'app-gwy-diagnostics'
  scope: appGwy
  properties: {
    logs: [
      {
        category: 'ApplicationGatewayAccessLog'
        enabled: true
        retentionPolicy: {
          days: retentionInDays
          enabled: true
        }
      }
      {
        category: 'ApplicationGatewayPerformanceLog'
        enabled: true
        retentionPolicy: {
          days: retentionInDays
          enabled: true
        }
      }
      {
        category: 'ApplicationGatewayFirewallLog'
        enabled: true
        retentionPolicy: {
          days: retentionInDays
          enabled: true
        }
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          days: retentionInDays
          enabled: true
        }
      }
    ]
    workspaceId: workspaceId
  }
}

output appGwyName string = appGwy.name
output appGwyId string = appGwy.id
output appGwyPublicDnsName string = pipName.properties.dnsSettings.fqdn
output appGwyPublicIpAddress string = pipName.properties.ipAddress
