ENVIRONMENTS=(staging production)
LOCATION='australiaeast'
GIT_REPO_URL='https://github.com/Azure/gitops-flux2-kustomize-helm-mt'

for i in "${ENVIRONMENTS[@]}"
do
    echo "deploying environment: $i"
    RG_NAME="aks-$i-rg"

    az group create --location $LOCATION --name $RG_NAME

    az deployment group create \
        --resource-group $RG_NAME \
        --name aks-deployment \
        --template-file ./main.bicep \
        --parameters @main.parameters.json \
        --parameters environment=$i \
        --parameters gitRepoUrl=$GIT_REPO_URL

    CLUSTER_NAME=$(az deployment group show --resource-group $RG_NAME --name aks-deployment --query 'properties.outputs.aksClusterName.value' -o tsv)

    az aks get-credentials -g $RG_NAME -n $CLUSTER_NAME --admin
	
done

