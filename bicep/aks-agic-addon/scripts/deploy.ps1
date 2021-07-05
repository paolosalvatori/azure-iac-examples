$resourceGroupName = 'aks-cbellee-rg'
$location = 'australiaeast'

az bicep build --file ../main.bicep

$rg = New-AzResourceGroup -Name $resourceGroupName -Location $location -Force

$deployment = New-AzResourceGroupDeployment `
	-ResourceGroupName $rg.ResourceGroupName `
	-Mode Incremental `
	-TemplateFile ../main.json `
	-TemplateParameterFile ../main.parameters.json `
	-WhatIfResultFormat FullResourcePayloads `
	-Prefix 'cbellee'
