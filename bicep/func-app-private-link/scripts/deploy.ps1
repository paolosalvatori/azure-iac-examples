$location = 'australiaeast'
$rgName = "func-$location-rg"

az bicep build --f ../main.bicep

$rg = New-AzResourceGroup -Name $rgName -Location $location -Force

New-AzResourceGroupDeployment `
    -Name 'apim-app-gwy-test-deploy' `
    -ResourceGroupName $rg.ResourceGroupName `
    -Mode Incremental `
    -TemplateFile ../main.json `
    -TemplateParameterFile ../main.parameters.json
