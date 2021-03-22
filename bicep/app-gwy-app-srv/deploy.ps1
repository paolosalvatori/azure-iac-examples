$location = 'australiaeast'
$resourceGroupName = 'app-svc-rg'
$dnsResourceGroupName = 'external-dns-zones-rg'
$deploymentName = 'app-gwy-app-svc-deployment'
$dnsDeploymentName = 'app-gwy-app-svc-dns-deployment'
$dnsZoneName = 'kainiindustries.net'
$hostName = 'gowebapp'

New-AzResourceGroup -Location $location -Name $resourceGroupName -Force

bicep build ./main.bicep
bicep build ./dns.bicep

$bytes = Get-Content -Path ./certs/gowebapp.kainiindustries.net/gowebapp.pfx -Encoding Byte
$base64Certificate = [System.Convert]::ToBase64String($bytes)

$deploymentOutput = New-AzResourceGroupDeployment `
	-Name $deploymentName `
	-ResourceGroupName $resourceGroupName `
	-TemplateFile ./main.json `
	-prefix 'app-svc' `
	-pfxCertificate $base64Certificate `
	-pfxCertificatePassword 'M1cr0soft' `
	-adminUserObjectId '57963f10-818b-406d-a2f6-6e758d86e259' `
	-containerImageName 'belstarr/blockchainapi:latest' `
	-containerPort '80' `
	-dnsZoneName $dnsZoneName `
	-hostName $hostName `
	-appServicePlanSku 'P1V2'

New-AzResourceGroupDeployment `
	-Name $dnsDeploymentName `
	-ResourceGroupName $dnsResourceGroupName `
	-TemplateFile ./dns.json `
	-dnsZoneName $dnsZoneName `
	-hostName $hostName `
	-AppGatewayFrontEndIpAddress $deploymentOutput.Outputs.appGatewayFrontEndIpAddress.Value
