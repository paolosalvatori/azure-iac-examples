param apimSku object = {
  name: 'Developer'
  capacity: 1
}
param gatewayHostName string = 'apim.internal'
param apiCertificatePassword string
param apiCertificate string
param subnetId string
param location string
param deployCertificates bool = false
param tags object
param privateDnsZoneName string
param hubVnetId string
param spokeVnetId string
param workspaceId string
param retentionInDays int = 30

var suffix = uniqueString(resourceGroup().id)
var apimName = 'api-mgmt-${suffix}'
var hostNameConfigurations = [
  {
    type: 'Proxy'
    encodedCertificate: apiCertificate
    defaultSslBinding: true
    hostName: gatewayHostName
    negotiateClientCertificate: false
    certificatePassword: apiCertificatePassword
  }
]

resource apim 'Microsoft.ApiManagement/service@2021-01-01-preview' = {
  name: apimName
  location: location
  sku: apimSku
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    publisherEmail: 'cbellee@microsoft.com'
    publisherName: 'KainiIndustries'
    notificationSenderEmail: 'apim-noreply@mail.windowsazure.com'
    hostnameConfigurations: (deployCertificates ? hostNameConfigurations : json('null'))
    virtualNetworkConfiguration: {
      subnetResourceId: subnetId
    }
    customProperties: {
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Protocols.Tls10': 'False'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Protocols.Tls11': 'False'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Protocols.Ssl30': 'False'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Ciphers.TripleDes168': 'False'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Backend.Protocols.Tls10': 'False'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Backend.Protocols.Tls11': 'False'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Backend.Protocols.Ssl30': 'False'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Protocols.Server.Http2': 'False'
    }
    virtualNetworkType: 'Internal'
  }
  dependsOn: []
}

resource apimProduct 'Microsoft.ApiManagement/service/products@2021-01-01-preview' = {
  name: '${apimName}/myProduct'
  properties: {
    displayName: 'My Product'
    description: 'My Product'
    terms: 'Terms for example product'
    subscriptionRequired: false
    state: 'published'
  }
  dependsOn: [
    apim
  ]
}

/* 
resource apimExternalApi 'Microsoft.ApiManagement/service/apis@2021-01-01-preview' = {
  parent: apim
  name: 'external-api'
  properties: {
    displayName: 'External API'
    subscriptionRequired: false
    apiRevision: '1'
    serviceUrl: '${webAppUrl}/api/external'
    path: 'external'
    protocols: [
      'https'
    ]
  }
} */

/* resource apimInternalApi 'Microsoft.ApiManagement/service/apis@2021-01-01-preview' = {
  parent: apim
  name: 'internal-api'
  properties: {
    displayName: 'Internal API'
    subscriptionRequired: false
    apiRevision: '1'
    serviceUrl: '${webAppUrl}/api/internal'
    path: 'internal'
    protocols: [
      'https'
    ]
  }
} */

/* resource apimExternalApiTest 'Microsoft.ApiManagement/service/apis/operations@2021-01-01-preview' = {
  parent: apimExternalApi
  name: 'external-test-call'
  properties: {
    displayName: 'External API test call'
    method: 'POST'
    urlTemplate: '/'
    templateParameters: []
    request: {
      queryParameters: [
        {
          name: 'name'
          type: 'string'
          values: [
            'myname'
          ]
        }
      ]
      headers: []
      representations: []
    }
    responses: [
      {
        statusCode: 200
        representations: [
          {
            contentType: 'application/json'
            sample: '{"name":"dave-external"}'
          }
        ]
        headers: []
      }
    ]
  }
  dependsOn: [
    apim
  ]
}

resource apimInternalApiTest 'Microsoft.ApiManagement/service/apis/operations@2021-01-01-preview' = {
  parent: apimInternalApi
  name: 'internal-test-call'
  properties: {
    displayName: 'Internal API test call'
    method: 'POST'
    urlTemplate: '/'
    templateParameters: []
    request: {
      queryParameters: [
        {
          name: 'name'
          type: 'string'
          values: [
            'myname'
          ]
        }
      ]
      headers: []
      representations: []
    }
    responses: [
      {
        statusCode: 200
        representations: [
          {
            contentType: 'application/json'
            sample: '{"name":"dave-internal"}'
          }
        ]
        headers: []
      }
    ]
  }
  dependsOn: [
    apim
  ]
} */

resource apimPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: privateDnsZoneName
}

resource apimGwyDnsRecord 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  parent: apimPrivateDnsZone
  name: gatewayHostName
  properties: {
    aRecords: [
      {
        ipv4Address: apim.properties.privateIPAddresses[0]
      }
    ]
    ttl: 3600
  }
}

/* resource apimPortalDnsRecord 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  parent: apimPrivateDnsZone
  name: 'portal'
  properties: {
    aRecords: [
      {
        ipv4Address: apim.properties.privateIPAddresses[0]
      }
    ]
    ttl: 3600
  }
} */

resource ApimHubVirtualNetworkDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${apimPrivateDnsZone.name}/${apimPrivateDnsZone.name}-hub-link'
  tags: tags
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: hubVnetId
    }
  }
}

resource ApimSpokeVirtualNetworkDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${apimPrivateDnsZone.name}/${apimPrivateDnsZone.name}-spoke-link'
  tags: tags
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: spokeVnetId
    }
  }
}

resource appGwyDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'apim-diagnostics'
  scope: apim
  properties: {
    logs: [
      {
        category: 'GatewayLogs'
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

output apimPrivateIpAddress string = apim.properties.privateIPAddresses[0]
output apimDnsName array = split(replace(apim.properties.gatewayUrl, 'https://', ''), '.')
output apimName string = apim.name
