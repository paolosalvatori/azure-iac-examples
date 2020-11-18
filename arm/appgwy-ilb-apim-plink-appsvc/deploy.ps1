$projectName = 'appgwy-ilb-apim-plink-func'
$resourceGroupName = "$projectName-rg"
$location = 'australiaeast'
$tags = @{"costCentre"="478132";"project"="$projectName"}
$containerName = 'nestedtemplates'
$dnsResourceGroupName = 'external-dns-zones-rg'
$domainName = 'kainiindustries.net'
$keyVaultUserObjectId = '57963f10-818b-406d-a2f6-6e758d86e259'
$certName = 'sslcert'
$certPassword = '=$D)#D$!?_[l0z+'

$now = Get-Date
$sasTokenExpiry = $now.AddHours(2).ToString('u') -replace ' ','T'

New-AzResourceGroup -Location $location -Name $resourceGroupName -Force

$storageDeployment = New-AzResourceGroupDeployment `
    -Name "deploy-storage-$((Get-Date).ToFileTime())" `
	-ResourceGroupName $resourceGroupName `
	-Mode Incremental `
	-TemplateFile './nestedtemplates/storage.json' `
	-ContainerName $containerName `
	-SasTokenExpiry $sasTokenExpiry

$keyVaultDeployment = New-AzResourceGroupDeployment `
    -Name "deploy-keyvault-$((Get-Date).ToFileTime())" `
	-ResourceGroupName $resourceGroupName `
	-Mode Incremental `
	-TemplateFile './nestedtemplates/keyvault.json' `
	-KeyVaultUserObjectId $keyVaultUserObjectId

<#
# upload ssl certificate to key vault
$pfxFilePath = Get-Item "./certs/api.$domainName/$certName.pfx"
$flag = [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::Exportable
$collection = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2Collection 
$collection.Import($pfxFilePath.FullName, $certPassword, $flag)
$pkcs12ContentType = [System.Security.Cryptography.X509Certificates.X509ContentType]::Pkcs12
$clearBytes = $collection.Export($pkcs12ContentType)
$fileContentEncoded = [System.Convert]::ToBase64String($clearBytes)
$secret = $fileContentEncoded | ConvertTo-SecureString -AsPlainText –Force
$secretContentType = 'application/x-pkcs12'

Set-AzKeyVaultSecret -VaultName $keyVaultDeployment.Outputs.keyVaultName.value -Name $certName -SecretValue $secret -ContentType $secretContentType -Debug
#>

# upload ARM template file to blob storage
az storage blob upload-batch -d $containerName -s ./nestedtemplates/ --pattern *.json --account-name $storageDeployment.Outputs.storageAccountName.value

$infraDeployment = New-AzResourceGroupDeployment `
	-Name "deploy-infra-$((Get-Date).ToFileTime())" `
	-ResourceGroupName $resourceGroupName `
	-Mode Incremental `
	-TemplateFile './azuredeploy.json' `
	-TemplateParameterFile './azuredeploy.parameters.json' `
	-StorageUri $storageDeployment.Outputs.storageContainerUri.value `
	-KeyVaultUri $keyVaultDeployment.Outputs.keyVaultUri.value `
	-KeyVaultName $keyVaultDeployment.Outputs.keyVaultName.value `
	-SasToken $storageDeployment.Outputs.storageAccountSasToken.value `
	-SslCertificateName $certName `
	-Tags $tags `
	-Verbose

# ./scripts/New-DnsRecord.ps1 -ResourceGroupName $dnsResourceGroupName -ZoneName $domainName -TargetName $infraDeployment.outputs.appGatewayPublicDnsName.value     
