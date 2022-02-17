REGION_1='australiaeast'
REGION_2='uksouth'
NAME='python'
RG_NAME="${NAME}-app-rg"
IMAGE_TAG="${NAME}-app:latest"
CONTAINER_PORT='8000'

# load env vars
. ./.env

# create resource group
az group create -l $REGION_1 -n $RG_NAME

# deploy Azure container Registry
az deployment group create \
    --resource-group $RG_NAME \
    --name acr-deployment \
    --template-file ./modules/acr.bicep \
    --parameters location=$REGION_1 \
    --parameters name=$NAME

# get ACR details from 'acr-deployment'
ACR_NAME=$(az deployment group show -n acr-deployment -g $RG_NAME --query properties.outputs.acrName.value -o tsv)
ACR_LOGIN_SERVER=$(az deployment group show -n acr-deployment -g $RG_NAME --query properties.outputs.acrLoginServer.value -o tsv)
ACR_PASSWORD=$(az acr credential show --name $ACR_NAME --query 'passwords[0].value' -o tsv)

# build and push container
docker build --platform linux/amd64 -t $ACR_LOGIN_SERVER/$IMAGE_TAG .
docker login -u $ACR_NAME -p $ACR_PASSWORD $ACR_LOGIN_SERVER
docker push $ACR_LOGIN_SERVER/$IMAGE_TAG

# infra deployment
az deployment group create \
    --resource-group $RG_NAME \
    --name infra-deployment \
    --template-file ./main.bicep \
    --parameters name=$NAME \
    --parameters region1=$REGION_1 \
    --parameters region2=$REGION_2 \
    --parameters imageNameAndTag=$IMAGE_TAG \
    --parameters containerPort=$CONTAINER_PORT \
    --parameters dbAdminUserName='dbadmin' \
    --parameters dbAdminPassword=$DB_ADMIN_PASSWORD
