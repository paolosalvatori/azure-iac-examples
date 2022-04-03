REGION_1='australiaeast'
REGION_2='uksouth'
NAME='python'
RG_NAME="${NAME}-app-rg"
COMMIT=$(git rev-parse --short HEAD)
IMAGE_TAG="v0.0.1-${COMMIT}"
IMAGE_NAME="${NAME}-app:${IMAGE_TAG}"
CONTAINER_PORT='8000'

# load the following env vars defined in an .env file in the same directory as this file (run.sh)
# DB_ADMIN_PASSWORD=<your database administrator password>
# ADMIN_USER_OBJECT_ID=<AAD user object id to grant full keyvault access policy>

. ./.env

# create resource group
az group create -l $REGION_1 -n $RG_NAME

# deploy Azure container Registry
az deployment group create \
    --resource-group $RG_NAME \
    --name acr-deployment \
    --template-file ./infra/modules/acr.bicep \
    --parameters location=$REGION_1 \
    --parameters name=$NAME

# get ACR details from 'acr-deployment'
ACR_NAME=$(az deployment group show -n acr-deployment -g $RG_NAME --query properties.outputs.acrName.value -o tsv)
ACR_LOGIN_SERVER=$(az deployment group show -n acr-deployment -g $RG_NAME --query properties.outputs.acrLoginServer.value -o tsv)
ACR_PASSWORD=$(az acr credential show --name $ACR_NAME --query 'passwords[0].value' -o tsv)

# build and push container
docker build --platform linux/amd64 -t "${ACR_LOGIN_SERVER}/${IMAGE_NAME}" ./app
docker login -u $ACR_NAME -p $ACR_PASSWORD $ACR_LOGIN_SERVER
docker push $ACR_LOGIN_SERVER/$IMAGE_NAME

# infra deployment
az deployment group create \
    --resource-group $RG_NAME \
    --name infra-deployment \
    --template-file ./infra/main.bicep \
    --parameters name=$NAME \
    --parameters region1=$REGION_1 \
    --parameters region2=$REGION_2 \
    --parameters imageNameAndTag=$IMAGE_NAME \
    --parameters containerPort=$CONTAINER_PORT \
    --parameters dbAdminUserName='dbadmin' \
    --parameters dbAdminPassword=$DB_ADMIN_PASSWORD \
    --parameters adminUserObjectId=$ADMIN_USER_OBJECT_ID

REGION1_URL=$(az deployment group show -n infra-deployment -g $RG_NAME --query properties.outputs.region1AppUrl.value -o tsv)
REGION2_URL=$(az deployment group show -n infra-deployment -g $RG_NAME --query properties.outputs.region2AppUrl.value -o tsv)

# ensure the apps in each region return the databse server ip of the opposite region
curl https://$REGION1_URL
curl https://$REGION2_URL
