$location = 'australiaeast'
$prefix = 'aks-private-endpoint-az'
$deploymentName = $('{0}-{1}-{2}' -f $prefix, 'deployment', (Get-Date).ToFileTime())
$rgName = "$prefix-rg"

# create resource group
if (!($rg = Get-AzResourceGroup -Name $rgName -Location $location -ErrorAction SilentlyContinue)) {
    $rg = New-AzResourceGroup -Name $rgName -Location $location
}

az bicep build --file ../azuredeploy.bicep

# start ARM template deployment
New-AzResourceGroupDeployment `
    -Name $deploymentName `
    -ResourceGroupName $rg.ResourceGroupName `
    -TemplateFile $PSScriptRoot\..\azuredeploy.json `
    -TemplateParameterFile $PSScriptRoot\..\azuredeploy.parameters.json `
    -Verbose