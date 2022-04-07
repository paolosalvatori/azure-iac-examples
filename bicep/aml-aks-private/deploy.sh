LOCATION='australiaeast'
PREFIX='aml-secure-8'
DEPLOYMENT_NAME='infra-deployment'
RG_NAME="${PREFIX}-rg"

# add current user to KeyVault acess policy
ADMIN_USER_OBJECT_ID=$(az ad signed-in-user show | jq .objectId -r)

# load .env file
. ./.env

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
    -p aksSystemNodeCount=3 \
    -p aadAdminGroupObjectIds=$ADMIN_GROUP_OBJECT_IDS \
    -p adminUserObjectId=$ADMIN_USER_OBJECT_ID
