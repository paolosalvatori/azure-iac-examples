bicep build ./main.bicep

az group create --name test-rg --location australiaeast
az deployment group create --template-file ./main.json --resource-group test-rg
