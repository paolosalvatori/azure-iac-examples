LOCATION='australiaeast'
PREFIX='aml-secure'
DEPLOYMENT_NAME='infra-deployment'
RG_NAME="${PREFIX}-rg"
WS_CLUSTER_ATTACH_NAME='aks-inference'

# load .env file
. ./.env

# install az ml extension
az extension add -n azure-cli-ml

# create resource group
az group create -n $RG_NAME -l $LOCATION

# execute Bicep template deployment
az deployment group create \
    -g $RG_NAME \
    -n $DEPLOYMENT_NAME \
    -f ./azuredeploy.bicep \
    -p ./azuredeploy.parameters.json \
    -p password=$DS_VM_PASSWORD \
    -p aksNodeCount=3 \
    -p adminUserObjectId=$ADMIN_USER_OBJECT_ID

