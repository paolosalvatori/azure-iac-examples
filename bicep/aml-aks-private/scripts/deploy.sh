location='australiaeast'
prefix='aml-aks-secure'
deploymentName='infra-deployment'
rgName="${prefix}-rg"

# load .env file
. ./.env

# create resource group
az group create -n $rgName -l $location

# start Bicep template deployment
az deployment group create \
    -g $rgName \
    -n $deploymentName \
    -f ../azuredeploy.bicep \
    -p ../azuredeploy.parameters.json \
    -p password=$DS_VM_PASSWORD \
    -p aksNodeCount=3 \
    -p adminUserObjectId="57963f10-818b-406d-a2f6-6e758d86e259"

# install az ml extension
az extension add -n azure-cli-ml

# update aks ml-fe ingress to use internal load balancer
az ml computetarget update aks \
    -n aks-inference \
    --load-balancer-subnet ScoringSubnet \
    --load-balancer-type InternalLoadBalancer \
    --workspace-name aml-ws-qdgxjt \
    -g $rgName

# 
az ml workspace update \
    -n aml-ws-qdgxjt \
    -g $rgName \
    -i aml-compute-qdgxjt
