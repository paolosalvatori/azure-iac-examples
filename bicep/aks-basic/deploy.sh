LOCATION='australiaeast'
SSH_KEY=$(cat ~/.ssh/id_rsa.pub)
ADMIN_GROUP_OBJECT_ID="f6a900e2-df11-43e7-ba3e-22be99d3cede"
LATEST_K8S_VERSION=$(az aks get-versions -l $LOCATION | jq -r -c '[.orchestrators[] | .orchestratorVersion][-1]')
RG_NAME="aks-basic-rg"

az group create --location $LOCATION --name $RG_NAME

az deployment group create \
    --resource-group $RG_NAME \
    --name aks-deployment \
    --template-file ./main.bicep \
    --parameters @main.parameters.json \
    --parameters location=$LOCATION \
    --parameters sshPublicKey="$SSH_KEY" \
    --parameters adminGroupObjectID=$ADMIN_GROUP_OBJECT_ID \
    --parameters aksVersion=$LATEST_K8S_VERSION \
    --parameters dnsPrefix='aks-basic'

CLUSTER_NAME=$(az deployment group show --resource-group $RG_NAME --name aks-deployment --query 'properties.outputs.aksClusterName.value' -o tsv)
az aks get-credentials -g $RG_NAME -n $CLUSTER_NAME --admin

# install azure-vote example app using helm chart
helm repo add azure-samples https://azure-samples.github.io/helm-charts/
helm install azure-vote azure-samples/azure-vote

# uninstall helm chart
# helm uninstall azure-vote