param location string
param tags object
param suffix string
param sku string = 'Premium'

var acrName = 'acr${suffix}'

resource acr 'Microsoft.ContainerRegistry/registries@2020-11-01-preview' = {
  name: acrName
  location: location
  tags: tags
  sku: {
    name: sku
  }
  properties: {
    adminUserEnabled: true
  }
}

output registryName string = acrName
output registryServer string = acr.properties.loginServer
output registryPassword string = listCredentials(acr.id, '2020-11-01-preview').passwords[0].value
output registryResourceId string = acr.id
