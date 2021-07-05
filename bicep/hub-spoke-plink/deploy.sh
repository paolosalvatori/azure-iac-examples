# vars
HUB_RG_NAME='test-hub-rg'
SPOKE_RG_NAME='test-spoke-rg'
LOCATION='australiaeast'
MYSQL_ADMIN_USER_NAME='dbadmin'
MYSQL_ADMIN_PASSWORD='M1cr0soft1234567890'
CONTAINER_IMAGE_NAME='belstarr/go-web-api:v1.0'

# transpile Bicep to ARM
bicep build ./hub.bicep
bicep build ./spoke.bicep
bicep build ./frontDoor.bicep

# hub deployment
az group create --name $HUB_RG_NAME --location $LOCATION

az deployment group create \
  --name HubDeployment \
	--template-file ./hub.json \
	--resource-group $HUB_RG_NAME

HUB_VNET_ID=$(az deployment group show \
  --name HubDeployment \
  --resource-group $HUB_RG_NAME \
  --query properties.outputs.vnetId.value -o tsv)

HUB_VNET_NAME=$(az deployment group show \
  --name HubDeployment \
  --resource-group $HUB_RG_NAME \
  --query properties.outputs.vnetName.value -o tsv)

# spoke deployment
az group create --name $SPOKE_RG_NAME --location $LOCATION

az deployment group create \
	--name SpokeDeployment \
	--template-file ./spoke.json \
	--resource-group $SPOKE_RG_NAME \
	--parameters mySqlAdminUserName=$MYSQL_ADMIN_USER_NAME \
	--parameters mySqlAdminPassword=$MYSQL_ADMIN_PASSWORD \
	--parameters hubVnetId=$HUB_VNET_ID \
	--parameters hubVnetName=$HUB_VNET_NAME \
	--parameters hubVnetResourceGroup=$HUB_RG_NAME \
	--parameters containerName=$CONTAINER_IMAGE_NAME

WEB_APP_HOST_NAME=$(az deployment group show \
  --name SpokeDeployment \
  --resource-group $SPOKE_RG_NAME \
  --query properties.outputs.webAppHostName.value -o tsv)

WEB_APP_NAME=$(az deployment group show \
  --name SpokeDeployment \
  --resource-group $SPOKE_RG_NAME \
  --query properties.outputs.webAppName.value -o tsv)

# front door deployment
az deployment group create \
  --name FrontDoorDeployment \
  --template-file ./frontDoor.json \
  --resource-group $HUB_RG_NAME \
  --parameters backendAddress=$WEB_APP_HOST_NAME

FRONT_DOOR_ID=$(az deployment group show \
  --name FrontDoorDeployment \
  --resource-group $HUB_RG_NAME \
  --query properties.outputs.frontDoorId.value -o tsv)

# patch front door unique id to web app access-restriction
az webapp config access-restriction add \
	--resource-group $SPOKE_RG_NAME \
	--name $WEB_APP_NAME \
	--priority 400 \
	--service-tag AzureFrontDoor.Backend \
	--http-header x-azure-fdid=$FRONT_DOOR_ID
	