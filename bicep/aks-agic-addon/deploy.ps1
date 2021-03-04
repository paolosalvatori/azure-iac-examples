
$rgName = 'aks-demo-rg'
$location = 'australiaeast'

bicep build ./main.bicep

$rg = New-AzResourceGroup -Name $rgName -Location $location -Force

$deployment = New-AzResourceGroupDeployment `
	-ResourceGroupName $rg.ResourceGroupName `
	-Mode Incremental `
	-TemplateFile ./main.json `
	-TemplateParameterFile ./main.parameters.json `
	-WhatIfResultFormat FullResourcePayloads

$deployment