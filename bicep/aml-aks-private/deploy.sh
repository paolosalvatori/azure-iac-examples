LOCATION='australiaeast'
PREFIX='aml-secure-test'
DEPLOYMENT_NAME='infra-deployment'
RG_NAME="${PREFIX}-rg"
WS_CLUSTER_ATTACH_NAME='aks-inference'

# load .env file
. ./.env

# install az ml extension
az extension add -n azure-cli-ml

# create resource group
az group create -n $RG_NAME -l $LOCATION

# start Bicep template deployment
az deployment group create \
    -g $RG_NAME \
    -n $DEPLOYMENT_NAME \
    -f ../azuredeploy.bicep \
    -p ../azuredeploy.parameters.json \
    -p password=$DS_VM_PASSWORD \
    -p aksNodeCount=3 \
    -p adminUserObjectId=$ADMIN_USER_OBJECT_ID

DEPLOYMENT_OUTPUT=$(az deployment group show \
        --name $DEPLOYMENT_NAME \
        --resource-group $RG_NAME \
        --query "{AML_WS_NAME:properties.outputs.amlWorkspaceName.value, AML_COMPUTE_NAME:properties.outputs.amlComputeName.value, SCORING_SUBNET_NAME:properties.outputs.scoringSubnetName.value, AKS_CLUSTER_ID:properties.outputs.aksClusterId.value}")

WS_NAME=$(echo $DEPLOYMENT_OUTPUT | jq .AML_WS_NAME -r)
COMPUTE_NAME=$(echo $DEPLOYMENT_OUTPUT | jq .AML_COMPUTE_NAME -r)
SUBNET_NAME=$(echo $DEPLOYMENT_OUTPUT | jq .SCORING_SUBNET_NAME -r)
CLUSTER_ID=$(echo $DEPLOYMENT_OUTPUT | jq .AKS_CLUSTER_ID -r)

# attach aks cluster to aml workspace
#az ml computetarget attach aks \
#    --compute-resource-id $CLUSTER_ID \
#    --name $WS_CLUSTER_ATTACH_NAME \
#    --resource-group $RG_NAME \
#    --workspace-name $WS_NAME

# update aks ml-fe ingress to use internal load balancer
#az ml computetarget update aks \
#    --name $WS_CLUSTER_ATTACH_NAME \
#    --load-balancer-subnet $SUBNET_NAME \
#    --load-balancer-type InternalLoadBalancer \
#    --workspace-name $WS_NAME \
#    --resource-group $RG_NAME

# update aml to build images using aml compute
#az ml workspace update \
#    --workspace-name $WS_NAME \
#    --resource-group $RG_NAME \
#    --image-build-compute $COMPUTE_NAME
