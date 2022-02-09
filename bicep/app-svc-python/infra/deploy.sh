LOCATION='australiaeast'
RG_NAME='python-app-rg'
PREFIX='pythonapp'
IMAGE_TAG='python-app:latest'

# create resource group
az group create -l $LOCATION -n $RG_NAME

# deploy Azure container Registry
az deployment group create \
    --resource-group $RG_NAME \
    --name acr-deployment \
    --template-file ./infra/acr.bicep \
    --parameters location=$LOCATION \
    --parameters prefix=$PREFIX

# get ACR details from 'acr-deployment'
ACR_NAME=$(az deployment group show -n acr-deployment -g $RG_NAME --query properties.outputs.acrName.value -o tsv)
ACR_LOGIN_SERVER=$(az deployment group show -n acr-deployment -g $RG_NAME --query properties.outputs.acrLoginServer.value -o tsv)
ACR_PASSWORD=$(az acr credential show --name $ACR_NAME --query 'passwords[0].value' -o tsv)

# build and push container
docker build -t $ACR_LOGIN_SERVER/$IMAGE_TAG .
docker login -u $ACR_NAME -p $ACR_PASSWORD $ACR_LOGIN_SERVER
docker push $ACR_LOGIN_SERVER/$IMAGE_TAG

# deploy app service
az deployment group create \
    --resource-group $RG_NAME \
    --name app-deployment \
    --resource-group $RG_NAME \
    --template-file ./infra/app.bicep \
    --parameters location=$LOCATION \
    --parameters acrName=$ACR_NAME \
    --parameters prefix=$PREFIX \
    --parameters imageNameAndTag=$IMAGE_TAG \
    --parameters containerPort='8000' 

APP_NAME=$(az deployment group show -n app-deployment -g $RG_NAME --query properties.outputs.appName.value -o tsv)
