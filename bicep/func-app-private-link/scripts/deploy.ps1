$location = 'australiaeast'
$rgName = "func-app-plink-$location-rg"

az bicep build --f ../main.bicep

$rg = New-AzResourceGroup -Name $rgName -Location $location -Force

New-AzResourceGroupDeployment `
    -Name 'func-app-plink-deployment' `
    -ResourceGroupName $rg.ResourceGroupName `
    -Mode Incremental `
    -VmAdminPassword 'M1cr0soft1234567890' `
    -TemplateFile ../main.json `
    -TemplateParameterFile ../main.parameters.json
