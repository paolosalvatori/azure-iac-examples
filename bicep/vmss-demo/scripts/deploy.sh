rgName='vmss-demo-rg'
adminUsername='localadmin'
adminPassword='M1cr0soft1234567890'
certPassword='M1cr0soft1234567890'
location='australiaeast'
deploymentName='infra-deployment'
hostname='myapp.kainiindustries.net'
sshPublicKey=$(cat ~/.ssh/id_rsa.pub)
vmssInstanceCount=3
appGwyHostName='myapp.kainiindustries.net'
aRecordName='myapp' 
dnsZoneName='kainiindustries.net'
forceScriptUpdate=$(date +%N)
dnsResourceGroupName='external-dns-zones-rg'
cert=$(cat ../certs/clientbase64)

az group create --name $rgName --location $location

az deployment group create \
    --name storageDeployment \
    --resource-group $rgName \
    --template-file ../infra/modules/storage.bicep \
    --parameters sasTokenExpiry=$(date -u +"2023-%m-%dT%H:%M:%SZ") \
    --parameters location=$location

CONTAINER_NAME=$(az deployment group show --name storageDeployment --resource-group $rgName --query 'properties.outputs.storageContainerName.value' -o tsv)
STORAGE_ACCOUNT_NAME=$(az deployment group show --name storageDeployment --resource-group $rgName --query 'properties.outputs.storageAccountName.value' -o tsv)
CONTAINER_URI=$(az deployment group show --name storageDeployment --resource-group $rgName --query 'properties.outputs.storageContainerUri.value' -o tsv)
SAS_TOKEN=$(az deployment group show --name storageDeployment --resource-group $rgName --query 'properties.outputs.storageAccountSasToken.value' -o tsv)

az storage azcopy blob upload --container $CONTAINER_NAME --account-name $STORAGE_ACCOUNT_NAME --source "../app/main" --recursive
az storage azcopy blob upload --container $CONTAINER_NAME --account-name $STORAGE_ACCOUNT_NAME --source "../scripts/install.sh" --recursive

az deployment group create \
    --name $deploymentName \
    --resource-group $rgName \
    --template-file ../infra/main.bicep \
    --parameters adminUsername=$adminUsername \
    --parameters adminPassword=$adminPassword \
    --parameters pfxCert="$cert" \
    --parameters pfxCertPassword=$certPassword \
    --parameters appGwyHostName=$hostName \
    --parameters vmssInstanceCount=$vmssInstanceCount \
    --parameters vmssCustomScriptUri=$CONTAINER_URI \
    --parameters appGwyHostName=$appGwyHostName \
    --parameters sshPublicKey="$sshPublicKey" \
    --parameters dnsResourceGroupName=$dnsResourceGroupName \
    --parameters dnsZoneName=$dnsZoneName \
    --parameters dnsARecordName=$aRecordName \
    --parameters forceScriptUpdate=$forceScriptUpdate \
    --parameters storageAccountName=$STORAGE_ACCOUNT_NAME \
    --parameters location=$location
