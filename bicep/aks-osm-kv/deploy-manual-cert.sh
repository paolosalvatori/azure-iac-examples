LOCATION='australiaeast'
SSH_KEY=$(cat ~/.ssh/id_rsa.pub)
ADMIN_GROUP_OBJECT_ID="f6a900e2-df11-43e7-ba3e-22be99d3cede"
LATEST_K8S_VERSION=$(az aks get-versions -l $LOCATION | jq -r -c '[.orchestrators[] | .orchestratorVersion][-1]')
RG_NAME='aks-osm-kv-rg'
DNS_PREFIX='aks-csi-workload-identity'

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
    --parameters dnsPrefix=$DNS_PREFIX

# az aks enable-addons -g $RG_NAME -n $CLUSTER_NAME --addons azure-keyvault-secrets-provider,open-service-mesh,web_application_routing --enable-secret-rotation

CLUSTER_NAME=$(az deployment group show --resource-group $RG_NAME --name aks-deployment --query 'properties.outputs.aksClusterName.value' -o tsv)
az aks get-credentials -g $RG_NAME -n $CLUSTER_NAME --admin

az aks update -g $RG_NAME -n $CLUSTER_NAME --enable-secret-rotation
KUBELET_IDENTITY_CLIENT_ID=$(az aks show -n $CLUSTER_NAME -g $RG_NAME --query addonProfiles.azureKeyvaultSecretsProvider.identity.clientId -o tsv)

# patch root-cert-secret-temaplte.yaml with base64 encoded private.key & certificate.crt
p=$(echo $(cat ./certs/private.key | base64 -w 0))
c=$(echo $(cat ./certs/certificate.crt | base64 -w 0))
sed "s/<<BASE_64_CERTIFICATE>>/${c}/g; s/<<BASE_64_PRIVATE_KEY>>/${p}/g" ./manifests/root-cert-secret-template.yaml > ./manifests/root-cert-secret.yaml

# create root-certificate secret object in kubernetes
k apply -f ./manifests/root-cert-secret.yaml -n osm-system

helm repo add osm https://openservicemesh.github.io/osm
helm repo update

helm install my-osm osm/osm --namespace osm-system

# install azure-vote example app using helm chart
# helm repo add azure-samples https://azure-samples.github.io/helm-charts/
# helm install azure-vote azure-samples/azure-vote

# uninstall helm chart
# helm uninstall azure-vote