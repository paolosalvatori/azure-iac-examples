rgName='vmss-demo-1-rg'
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

# build app
cd ../app
GOOS=linux GOARCH=amd64 go build
cd ../scripts

# create RG
az group create --name $rgName --location $location

# deploy storage account
az deployment group create \
    --name storageDeployment \
    --resource-group $rgName \
    --template-file ../infra/modules/storage.bicep \
    --parameters sasTokenExpiry=$(date -u +"2023-%m-%dT%H:%M:%SZ") \
    --parameters location=$location

# get deployment outputs
CONTAINER_NAME=$(az deployment group show --name storageDeployment --resource-group $rgName --query 'properties.outputs.storageContainerName.value' -o tsv)
STORAGE_ACCOUNT_NAME=$(az deployment group show --name storageDeployment --resource-group $rgName --query 'properties.outputs.storageAccountName.value' -o tsv)
CONTAINER_URI=$(az deployment group show --name storageDeployment --resource-group $rgName --query 'properties.outputs.storageContainerUri.value' -o tsv)
SAS_TOKEN=$(az deployment group show --name storageDeployment --resource-group $rgName --query 'properties.outputs.storageAccountSasToken.value' -o tsv)

# upload script & binary
az storage azcopy blob upload --container $CONTAINER_NAME --account-name $STORAGE_ACCOUNT_NAME --source "../app/vmss-test-app" --recursive
az storage azcopy blob upload --container $CONTAINER_NAME --account-name $STORAGE_ACCOUNT_NAME --source "../scripts/install.sh" --recursive

# deploy infra
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

# scale-up to maximum number of instances
echo "increasing load to maximum capacity..."
echo "GET https://myapp.kainiindustries.net" | ./vegeta -cpus 4 attack -duration=15m -insecure > /dev/null 2>&1

# wait until at least 3 instances are in the 'Deleting (Running)' state, then add some more load
DELETING_COUNT=$(az vmss get-instance-view -g $rgName -n vmss-76uh2ncyuah6q | jq '.virtualMachine.statusesSummary[] | select(.code == "ProvisioningState/deleting").count')

while [[ $DELETING_COUNT -le 3 ]]
do 
    DELETING_COUNT=$(az vmss get-instance-view -g $rgName -n vmss-76uh2ncyuah6q | jq '.virtualMachine.statusesSummary[] | select(.code == "ProvisioningState/deleting").count')
    sleep 1m
done

echo "GET https://myapp.kainiindustries.net" | ./vegeta -cpus 4 attack -duration=15m -insecure > /dev/null 2>&1




:'
VMSS_NAME=$(az vmss list --resource-group $rgName --query [].name -o tsv)
NUM_VMSS_INSTANCES=$(az vmss list-instances --resource-group $rgName --name $VMSS_NAME | jq '. | length')

while [[ $NUM_VMSS_INSTANCES -ge 5 ]] 
do 
    NUM_VMSS_INSTANCES=$(az vmss list-instances --resource-group $rgName --name $VMSS_NAME | jq '. | length')
    "echo sleeping for 1 minute while instance number is reduced to 5"
    sleep 1m
done

if [[ $NUM_VMSS_INSTANCES -le 5 ]] 
then
    # scale back up if half the instances are in the Deleted (Running) state
    # notice that no new instances are created whilst previous instances are in the 'Deleting (Running)' state 
    echo "increasing load during ..."
    echo "GET https://myapp.kainiindustries.net" | ./vegeta -cpus 4 attack -duration=15m -insecure > /dev/null 2>&1
else
    echo "VM scale set only has $NUM_VMSS_INSTANCES instance(s)"
fi
'
