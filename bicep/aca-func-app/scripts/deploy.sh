RG_NAME='aca-func-go-rg'
LOCATION='australiaeast'
ENVIRONMENT=dev
SEMVER=0.1.0
TAG="$ENVIRONMENT-$SEMVER"
IMAGE="func-api:$TAG"

echo "IMAGE: $IMAGE"

az group create --name $RG_NAME --location $LOCATION

az deployment group create \
--resource-group $RG_NAME \
--name 'acr-deployment' \
--template-file ../infra/modules/acr.bicep \
--parameters location=$LOCATION

ACR_NAME=$(az deployment group show --resource-group $RG_NAME --name 'acr-deployment' --query properties.outputs.acrName.value -o tsv)

# build image in ACR
az acr build -r $ACR_NAME -t $IMAGE -f ../func/Dockerfile ../func

az deployment group create \
--resource-group $RG_NAME \
--name 'aca-deployment' \
--template-file ../infra/main.bicep \
--parameters location=$LOCATION \
--parameters imageName="$ACR_NAME.azurecr.io/$IMAGE" \
--parameters funcName='todofunc' \
--parameters funcPort='80' \
--parameters acrName=$ACR_NAME
	