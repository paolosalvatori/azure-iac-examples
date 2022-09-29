LOCATION='australiaeast'
PREFIX='aml-private-01'
DEPLOYMENT_NAME='infra-deployment'
RG_NAME="${PREFIX}-rg"

LATEST_AKS_VERSION=$(az aks get-versions --location $LOCATION | jq '.orchestrators[-1].orchestratorVersion' -r)

# add current user to KeyVault acess policy
ADMIN_USER_OBJECT_ID=$(az ad signed-in-user show --query id -o tsv)

# load .env file
. ./.env

# create resource group
az group create -n $RG_NAME -l $LOCATION

# execute Bicep template deployment
az deployment group create \
    --resource-group $RG_NAME \
    --name $DEPLOYMENT_NAME \
    --template-file ./main.bicep \
    --parameters ./main.parameters.json \
    --parameters password=$DS_VM_PASSWORD \
    --parameter aksVersion=$LATEST_AKS_VERSION \
    --parameters aksNodeCount=3 \
    --parameters aksSystemNodeCount=3 \
    --parameters aadAdminGroupObjectIds=$ADMIN_GROUP_OBJECT_IDS \
    --parameters adminUserObjectId=$ADMIN_USER_OBJECT_ID
