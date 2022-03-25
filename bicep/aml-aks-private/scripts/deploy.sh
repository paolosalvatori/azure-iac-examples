location='australiaeast'
prefix='aml-aks-private-endpoint'
deploymentName='infra-deployment'
rgName="${prefix}-rg"
CLOUD_INIT_CONTENT=$(cat ./cloudinit.txt)

# create resource group
az group create -n $rgName -l $location

# start Bicep template deployment
az deployment group create \
    -g $rgName \
    -n $deploymentName \
    -f ../azuredeploy.bicep \
    -p ../azuredeploy.parameters.json \
    -p adminUserObjectId="57963f10-818b-406d-a2f6-6e758d86e259"
