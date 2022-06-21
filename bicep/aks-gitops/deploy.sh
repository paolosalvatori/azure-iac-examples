ENVIRONMENTS=(staging production)
LOCATION='australiaeast'
GIT_REPO_URL='https://github.com/Azure/gitops-flux2-kustomize-helm-mt'
SSH_KEY=$(cat ~/.ssh/id_rsa.pub)
ADMIN_GROUP_OBJECT_ID="f6a900e2-df11-43e7-ba3e-22be99d3cede"
LATEST_K8S_VERSION_IN_REGION=$(az aks get-versions -l $LOCATION | jq -r -c '[.orchestrators[] | .orchestratorVersion][-1]')

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
        --parameters gitRepoUrl=$GIT_REPO_URL \
        --parameters sshPublicKey="$SSH_KEY" \
        --parameters adminGroupObjectID=$ADMIN_GROUP_OBJECT_ID \
        --parameters aksVersion=$LATEST_K8S_VERSION_IN_REGION

    CLUSTER_NAME=$(az deployment group show --resource-group $RG_NAME --name aks-deployment --query 'properties.outputs.aksClusterName.value' -o tsv)

    az aks get-credentials -g $RG_NAME -n $CLUSTER_NAME --admin
	
done

