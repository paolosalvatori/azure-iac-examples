RG_NAME='aks-cbellee-rg'
LOCATION='australiaeast'
PREFIX='cbellee'
WIN_ADMIN_PASSWORD='M1cr0soft1234567890'

az group create --location $LOCATION --name $RG_NAME

az deployment group create \
    --resource-group $RG_NAME \
    --name aks-deployment \
    --template-file ./main.bicep \
    --parameters @main.parameters.json \
    --parameters prefix=$PREFIX \
    --parameters windowsAdminPassword=$WIN_ADMIN_PASSWORD --what-if

CLUSTER_NAME=$(az deployment group show --resource-group $RG_NAME --name aks-deployment --query 'properties.outputs.aksClusterName.value' -o tsv)

az aks get-credentials -g $RG_NAME -n $CLUSTER_NAME --admin
