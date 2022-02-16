LOCATION='australiaeast'
RG_NAME='python-test-rg'
NAME='pythontest'
IMAGE_TAG='python-test:latest'

# create resource group
az group create -l $LOCATION -n $RG_NAME

# deploy Azure container Registry
az deployment group create \
    --resource-group $RG_NAME \
    --name acr-deployment \
    --template-file ./infra/acr.bicep \
    --parameters location=$LOCATION \
    --parameters name=$NAME

# get ACR details from 'acr-deployment'
ACR_NAME=$(az deployment group show -n acr-deployment -g $RG_NAME --query properties.outputs.acrName.value -o tsv)
ACR_LOGIN_SERVER=$(az deployment group show -n acr-deployment -g $RG_NAME --query properties.outputs.acrLoginServer.value -o tsv)
ACR_PASSWORD=$(az acr credential show --name $ACR_NAME --query 'passwords[0].value' -o tsv)

# build and push container
docker build --platform linux/amd64 -t $ACR_LOGIN_SERVER/$IMAGE_TAG .
docker login -u $ACR_NAME -p $ACR_PASSWORD $ACR_LOGIN_SERVER
docker push $ACR_LOGIN_SERVER/$IMAGE_TAG

# deploy vnet
az deployment group create \
    --resource-group $RG_NAME \
    --name vnet-deployment \
    --resource-group $RG_NAME \
    --template-file ./infra/vnet.bicep \
    --parameters location=$LOCATION

SUBNET_ID=$(az deployment group show --resource-group $RG_NAME --name=vnet-deployment --query properties.outputs.vnetIntegrationSubnetId.value -o tsv)

# deploy app service
az deployment group create \
    --resource-group $RG_NAME \
    --name app-deployment \
    --template-file ./infra/app.bicep \
    --parameters location=$LOCATION \
    --parameters acrName=$ACR_NAME \
    --parameters subnetId=$SUBNET_ID \
    --parameters imageNameAndTag=$IMAGE_TAG \
    --parameters containerPort='8000'
