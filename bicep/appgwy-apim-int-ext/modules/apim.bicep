param apimSku object = {
  name: 'Developer'
  capacity: 1
}
//param portalHostName string = 'portal.kainiindustries.net'
param gatewayHostName string = 'api.kainiindustries.net'
//param portalCertificatePassword string
param apiCertificatePassword string
param apiCertificate string
param subnetId string
//param keyVaultUri string
//param keyVaultName string
param location string
param deployCertificates bool = false
param tags object
param apimPrivateDnsZoneName string
param hubVnetId string
param spokeVnetId string
param webAppUrl string

var suffix = uniqueString(resourceGroup().id)
var apimName = 'api-mgmt-${suffix}'
//var apimServiceIdentityResourceId = '${apim.id}/providers/Microsoft.ManagedIdentity/Identities/default'
var hostNameConfigurations = [
  /*   {
    type: 'Portal'
    keyVaultId: '${keyVaultUri}secrets/apimportal'
    defaultSslBinding: false
    hostName: portalHostName
    negotiateClientCertificate: false
    certificatePassword: portalCertificatePassword
  } */
  {
    type: 'Proxy'
    //keyVaultId: '${keyVaultUri}secrets/apimapi'
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

/* resource keyVaultName_add 'Microsoft.KeyVault/vaults/accessPolicies@2021-04-01-preview' = {
  name: '${keyVaultName}/add'
  properties: {
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: reference(apimServiceIdentityResourceId, '2015-08-31-PREVIEW', 'Full').properties.principalId
        permissions: {
          secrets: [
            'get'
            'list'
          ]
          certificates: [
           'get'
           'list'  
          ]
        }
      }
    ]
  }
}
*/

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
}

resource apimInternalApi 'Microsoft.ApiManagement/service/apis@2021-01-01-preview' = {
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
}

resource apimExternalApiTest 'Microsoft.ApiManagement/service/apis/operations@2021-01-01-preview' = {
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
}

/* resource apimExternalApiTestPolicy 'Microsoft.ApiManagement/service/apis/operations/policies@2018-06-01-preview' = {
  parent: apimExternalApiTest
  name: 'policy'
  properties: {
    policyContent: '<policies>\r\n  <inbound>\r\n    <base />\r\n    <mock-response status-code="200" content-type="application/json" />\r\n  </inbound>\r\n  <backend>\r\n    <base />\r\n  </backend>\r\n  <outbound>\r\n    <base />\r\n  </outbound>\r\n  <on-error>\r\n    <base />\r\n  </on-error>\r\n</policies>'
    contentFormat: 'xml'
  }
  dependsOn: [
    apimExternalApi
    apim
  ]
}

resource apimInternalApiTestPolicy 'Microsoft.ApiManagement/service/apis/operations/policies@2018-06-01-preview' = {
  parent: apimInternalApiTest
  name: 'policy'
  properties: {
    policyContent: '<policies>\r\n  <inbound>\r\n    <base />\r\n    <mock-response status-code="200" content-type="application/json" />\r\n  </inbound>\r\n  <backend>\r\n    <base />\r\n  </backend>\r\n  <outbound>\r\n    <base />\r\n  </outbound>\r\n  <on-error>\r\n    <base />\r\n  </on-error>\r\n</policies>'
    contentFormat: 'xml'
  }
  dependsOn: [
    apimInternalApi
    apim
  ]
}
 */
resource apimPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  location: 'global'
  tags: tags
  name: apimPrivateDnsZoneName
  properties: {}
}

resource apimGwyDnsRecord 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  parent: apimPrivateDnsZone
  name: 'api'
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

output apimPrivateIpAddress string = apim.properties.privateIPAddresses[0]
output apimDnsName array = split(replace(apim.properties.gatewayUrl, 'https://', ''), '.')
