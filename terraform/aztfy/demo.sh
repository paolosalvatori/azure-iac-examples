# install Terraform
# https://learn.hashicorp.com/tutorials/terraform/install-cli

# install AzTfy
# https://github.com/Azure/aztfy

AZTFY_SUBSCRIPTION_ID=$(az account show --query id -o tsv)
AZTFY_BACKEND_CONFIG=""
RG_NAME="aztfydemo-rg"

mkdir ./output
aztfy --output-dir ./output $RG_NAME 