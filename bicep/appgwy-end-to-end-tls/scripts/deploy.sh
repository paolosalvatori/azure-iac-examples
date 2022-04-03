RG_NAME='appgwy-e2e-tls-bash-rg'
LOCATION='australiaeast'
SCRIPT_NAME='iis.ps1'
CONTAINER_NAME='scripts'
DOMAIN_NAME='kainiindustries.net'
DNS_ZONE_RG_NAME='external-dns-zones-rg'
CERT_FILE_PATH='../certs/api.kainiindustries.net.pfx'

. ./.env

# create .pfx from certificate & private key
# openssl pkcs12 -export -out ../certs/api.kainiindustries.net.pfx -inkey ../certs/private.key -in ../certs/certificate.crt

az group create -g $RG_NAME -l $LOCATION

STORAGE_ACCOUNT_INFO=$(az deployment group create \
    -g $RG_NAME \
    --template-file ../modules/storage.bicep \
    --name 'storage-deployment' \
    --parameters location=$LOCATION \
    --parameters containerName=$CONTAINER_NAME \
    --query "{CONTAINER_URI:properties.outputs.storageContainerUri.value, STORAGE_ACCOUNT_NAME:properties.outputs.storageAccountName.value}")

STORAGE_CONTAINER_URI=$(echo $STORAGE_ACCOUNT_INFO | jq .CONTAINER_URI -r)
STORAGE_ACCOUNT_NAME=$(echo $STORAGE_ACCOUNT_INFO | jq .STORAGE_ACCOUNT_NAME -r)

az storage blob upload --account-name $STORAGE_ACCOUNT_NAME --file ./$SCRIPT_NAME -c $CONTAINER_NAME -n $SCRIPT_NAME

KEY_VAULT_NAME=$(az deployment group create \
    -g $RG_NAME \
    --template-file ../modules/keyvault.bicep \
    --name 'keyvault-deployment' \
    --parameters location=$LOCATION \
    --parameters adminObjectId=$ADMIN_USER_OBJECT_ID \
    --query 'properties.outputs.keyVaultName.value' -o tsv)

CERT_INFO=$(az keyvault certificate import \
    --vault-name $KEY_VAULT_NAME \
    -n ssl-cert \
    -f $CERT_FILE_PATH \
    --password $CERT_PASSWORD \
    --query "{SID:sid, THUMBPRINT:x509ThumbprintHex}")

CERT_SECRET_ID=$(echo $CERT_INFO | jq .SID -r)
CERT_THUMBPRINT=$(echo $CERT_INFO | jq .THUMBPRINT -r)

az deployment group create \
    -g $RG_NAME \
    --template-file ../main.bicep \
    --name 'infra-deployment' \
    --parameters location=$LOCATION \
    --parameters domainName=$DOMAIN_NAME \
    --parameters storageAccountName=$STORAGE_ACCOUNT_NAME \
    --parameters storageContainerUri=$STORAGE_CONTAINER_URI \
    --parameters scriptName=$SCRIPT_NAME \
    --parameters backendPort=443 \
    --parameters frontendPort=443 \
    --parameters dnsZoneResourceGroup=$DNS_ZONE_RG_NAME \
    --parameters keyVaultName=$KEY_VAULT_NAME \
    --parameters frontEndHostName="api.$DOMAIN_NAME" \
    --parameters pfxCertSecretId=$CERT_SECRET_ID \
    --parameters pfxCertThumbprint=$CERT_THUMBPRINT \
    --parameters winVmPassword=$VM_PASSWORD
