param suffix string
param skuName string = 'Standard'
param gatewaySku object = {
  name: 'WAF_v2'
  tier: 'WAF_v2'
  capacity: '1'
}

param subnetId string

/* @secure()
param apimPortalSslCert string
 */
@secure()
param apimGatewaySslCert string 

/* @secure()
param apimPortalSslCertPassword string
 */
@secure()
param apimGatewaySslCertPassword string

@secure()
param rootSslCert string

@secure()
param rootSslCertPassword string

param frontEndPort int = 443
param requestTimeOut int = 180
param apiHostName string = 'api.kainiindustries.net'
//param portalHostName string = 'portal.kainiindustries.net'

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
/*       {
        name: 'apim-portal-cert'
        properties: {
          data: apimPortalSslCert
          password: apimPortalSslCertPassword
        }
      } */
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
    ]
    frontendPorts: [
      {
        name: 'frontend-port'
        properties: {
          port: frontEndPort
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'apim-backend'
        properties: {
          backendAddresses: [
            {
              fqdn: apiHostName
            }
          ]
        }
      }
/*       {
        name: 'apim-portal-backend'
        properties: {
          backendAddresses: [
            {
              fqdn: portalHostName
            }
          ]
        }
      } */
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
          pickHostNameFromBackendAddress: true
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
      /* {
        name: 'apim-portal-poolsetting'
        properties: {
          port: frontEndPort
          protocol: 'Https'
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: false
          requestTimeout: requestTimeOut
          probe: {
            id: resourceId('Microsoft.Network/applicationGateways/probes', appGwyName, 'apim-portal-probe')
          }
        }
      } */
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
          hostName: apiHostName
          requireServerNameIndication: true
          customErrorConfigurations: []
        }
      }
      /* {
        name: 'apim-portal-listener'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', appGwyName, 'frontend')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', appGwyName, 'frontend-port')
          }
          protocol: 'Https'
          sslCertificate: {
            id: resourceId('Microsoft.Network/applicationGateways/sslCertificates', appGwyName, 'apim-portal-cert')
          }
          hostName: portalHostName
          requireServerNameIndication: true
          customErrorConfigurations: []
        }
      } */
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
    ]
    requestRoutingRules: [
      /* {
        name: 'apim-portal-rule'
        properties: {
          ruleType: 'Basic'
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', appGwyName, 'apim-portal-listener')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', appGwyName, 'apim-portal-backend')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', appGwyName, 'apim-portal-poolsetting')
          }
        }
      } */
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
    ]
    probes: [
      {
        name: 'apim-gateway-probe'
        properties: {
          protocol: 'Https'
          host: apiHostName
          path: '/status-0123456789abcdef'
          interval: 30
          timeout: 120
          unhealthyThreshold: 8
          pickHostNameFromBackendHttpSettings: false
          minServers: 0
          match: {}
        }
      }
      /* {
        name: 'apim-portal-probe'
        properties: {
          protocol: 'Https'
          host: portalHostName
          path: '/signin'
          interval: 60
          timeout: 300
          unhealthyThreshold: 8
          pickHostNameFromBackendHttpSettings: false
          minServers: 0
          match: {}
        }
      } */
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

output appGwyName string = appGwy.name
output appGwyId string = appGwy.id
output appGwyPublicDnsName string = pipName.properties.dnsSettings.fqdn
output appGwyPublicIpAddress string = pipName.properties.ipAddress
