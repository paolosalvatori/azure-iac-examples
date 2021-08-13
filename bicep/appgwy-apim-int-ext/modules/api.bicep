param apimName string
param apiName string
param functionUri string

var apiSchemaGuid = guid(resourceGroup().id)

resource api 'Microsoft.ApiManagement/service/apis@2021-01-01-preview' = {
  name: '${apimName}/${apiName}'
  properties: {
    displayName: apimName
    apiRevision: '1'
    description: 'Example Todo API Definition'
    subscriptionRequired: false
    serviceUrl: functionUri
    protocols: [
      'https'
    ]
    isCurrent: true
    path: 'external'
  }
}

resource apiSchema 'Microsoft.ApiManagement/service/apis/schemas@2021-01-01-preview' = {
  name: '${apimName}/${apiName}/${apiSchemaGuid}'
  properties: {
    contentType: 'application/vnd.oai.openapi.components+json'
    document: {}
  }
}

resource apiDeleteOperation 'Microsoft.ApiManagement/service/apis/operations@2021-01-01-preview' = {
  name: '${apimName}/${apiName}/delete-api-deleteitem-1'
  properties: {
    displayName: '/api/deleteItem/1 - DELETE'
    method: 'DELETE'
    urlTemplate: '/api/deleteItem/1'
    templateParameters: []
    description: 'Auto generated using Swagger Inspector'
    responses: [
      {
        statusCode: 200
        description: 'Auto generated using Swagger Inspector'
        representations: [
          {
            contentType: 'application/json'
            schemaId: apiSchemaGuid
            typeName: 'ApiDeleteItem1Delete200ApplicationJsonResponse'
          }
        ]
        headers: []
      }
    ]
  }
}

resource apiGetCompletedItemsOperation 'Microsoft.ApiManagement/service/apis/operations@2021-01-01-preview' = {
  name: '${apimName}/${apiName}/get-api-getcompleteditems'
  properties: {
    displayName: '/api/getCompletedItems - GET'
    method: 'GET'
    urlTemplate: '/api/getCompletedItems'
    templateParameters: []
    description: 'Auto generated using Swagger Inspector'
    responses: [
      {
        statusCode: 200
        description: 'Auto generated using Swagger Inspector'
        representations: [
          {
            contentType: 'application/json'
            schemaId: apiSchemaGuid
            typeName: 'ApiGetCompletedItemsGet200ApplicationJsonResponse'
          }
        ]
        headers: []
      }
    ]
  }
}

resource getIncompleteItemsOperation 'Microsoft.ApiManagement/service/apis/operations@2021-01-01-preview' = {
  name: '${apimName}/${apiName}/get-api-getincompleteitems'
  properties: {
    displayName: '/api/getIncompleteItems - GET'
    method: 'GET'
    urlTemplate: '/api/getIncompleteItems'
    templateParameters: []
    description: 'Auto generated using Swagger Inspector'
    responses: [
      {
        statusCode: 200
        description: 'Auto generated using Swagger Inspector'
        representations: [
          {
            contentType: 'application/json'
            schemaId: apiSchemaGuid
            typeName: 'ApiGetIncompleteItemsGet200ApplicationJsonResponse'
          }
        ]
        headers: []
      }
    ]
  }
}

resource apiCreateItemOperation 'Microsoft.ApiManagement/service/apis/operations@2021-01-01-preview' = {
  name: '${apimName}/${apiName}/post-api-createitem'
  properties: {
    displayName: '/api/createItem - POST'
    method: 'POST'
    urlTemplate: '/api/createItem'
    templateParameters: []
    description: 'Auto generated using Swagger Inspector'
    request: {
      queryParameters: [
        {
          name: 'description'
          type: 'string'
          values: []
          schemaId: apiSchemaGuid
          typeName: 'ApiCreateItemPostRequest'
        }
      ]
      headers: []
      representations: []
    }
    responses: [
      {
        statusCode: 200
        description: 'Auto generated using Swagger Inspector'
        representations: [
          {
            contentType: 'application/json'
            schemaId: apiSchemaGuid
            typeName: 'ApiCreateItemPost200ApplicationJsonResponse'
          }
        ]
        headers: []
      }
    ]
  }
}

resource apiUpdateItemOperation 'Microsoft.ApiManagement/service/apis/operations@2021-01-01-preview' = {
  name: '${apimName}/${apiName}/post-api-updateitem-1'
  properties: {
    displayName: '/api/updateItem/1 - POST'
    method: 'POST'
    urlTemplate: '/api/updateItem/1'
    templateParameters: []
    description: 'Auto generated using Swagger Inspector'
    request: {
      queryParameters: [
        {
          name: 'completed'
          type: 'boolean'
          values: []
          schemaId: apiSchemaGuid
          typeName: 'ApiUpdateItem2PostRequest'
        }
      ]
      headers: []
      representations: []
    }
    responses: [
      {
        statusCode: 200
        description: 'Auto generated using Swagger Inspector'
        representations: [
          {
            contentType: 'application/json'
            schemaId: apiSchemaGuid
            typeName: 'ApiUpdateItem2Post200ApplicationJsonResponse'
          }
        ]
        headers: []
      }
    ]
  }
}
