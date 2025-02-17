@description('Specifies the name of the Azure Machine Learning workspace to which compute instance will be deployed')
param workspaceName string

param subnetId string

@description('Specifies the name of the Azure Machine Learning compute instance to be deployed')
param computeName string

@description('Location of the Azure Machine Learning workspace.')
param location string = resourceGroup().location

@description('The VM size for compute instance')
param vmSize string = 'Standard_DS3_v2'

@description('AAD tenant id of the user to which compute instance is assigned to')
param tenantId string = subscription().tenantId

@description('AAD object id of the user to which compute instance is assigned to')
param objectId string

@description('inline command')
param inlineCommand string = 'ls'

@description('Specifies the cmd arguments of the creation script in the storage volume of the Compute Instance.')
param creationScript_cmdArguments string = ''

resource workspace_compute 'Microsoft.MachineLearningServices/workspaces/computes@2021-07-01' = {
  name: '${workspaceName}/${computeName}'
  location: location
  properties: {
    computeType: 'ComputeInstance'
    properties: {
      vmSize: vmSize
      subnet: {
        id: subnetId
      }
      personalComputeInstanceSettings: {
        assignedUser: {
          objectId: objectId
          tenantId: tenantId
        }
      }
      setupScripts: {
        scripts: {
          creationScript: {
            scriptSource: 'inline'
            scriptData: base64(inlineCommand)
            scriptArguments: creationScript_cmdArguments
          }
        }
      }
    }
  }
}

output amlComputeName string = workspace_compute.name
