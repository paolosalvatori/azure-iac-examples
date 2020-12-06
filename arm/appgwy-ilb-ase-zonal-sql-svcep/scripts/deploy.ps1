param(
	[string]
	$Location = 'australiaeast',

	[string]
	$Prefix = 'appgwy-ilb-ase-zonal-sql-svcep',

	[string]
	$ContainerName = 'nestedtemplates',

	[object]
	$Tags = @{
		'environment' = 'dev'
		'app'         = 'testapp'
	},

	[string]
	$DbAdminPassword = 'yourSuperS3cretP@ssw0rd'
)

$ProgressPreference = 'SilentlyContinue'

<# function Set-PfxAsKeyVaultSecret {

	[CmdletBinding()]
	param (
		[Parameter()]
		[System.IO.FileInfo]
		$PfxFile,

		[Parameter()]
		[String]
		$CertificatePassword,

		[Parameter()]
		[String]
		$SecretContentType = 'application/x-pkcs12',

		[Parameter()]
		[String]
		$KeyVaultName,

		[Parameter()]
		[String]
		$CertificateName
	)
	
	$collection = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2Collection
	$flag = [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::Exportable
	$collection.Import($PfxFile.FullName, $CertificatePassword, $flag)
	$pkcs12ContentType = [System.Security.Cryptography.X509Certificates.X509ContentType]::Pkcs12
	$clearBytes = $collection.Export($pkcs12ContentType)
	$fileContentEncoded = [System.Convert]::ToBase64String($clearBytes)
	$secret = ConvertTo-SecureString -String $fileContentEncoded -AsPlainText -Force
	Set-AzKeyVaultSecret -VaultName $KeyVaultName -Name $($pfxFile.BaseName -replace '\.', '-') -SecretValue $secret -ContentType $SecretContentType
} #>

$rgName = "$prefix-rg"
$certName = 'api.kainiindustries.net'

# get executing user's mail & objectId to add to keyvault access policy 
$ctx = Get-AzContext
$keyVaultUserEmailAddress = (Get-AzADUser -Mail $ctx.Account).Mail
$keyVaultUserObjectId = (Get-AzADUser -Mail $ctx.Account).Id

# create resource group
if (!($rg = Get-AzResourceGroup -Name $rgName -Location $location -ErrorAction SilentlyContinue)) {
	$rg = New-AzResourceGroup -Name $rgName -Location $location -Verbose
}

# deploy storage account to hold child ARM templates
$sasTokenExpiry = (Get-Date).AddHours(2).ToString('u') -replace ' ', 'T'
$storageDeployment = New-AzResourceGroupDeployment `
	-Name "deploy-storage" `
	-ResourceGroupName $rg.ResourceGroupName `
	-Mode Incremental `
	-TemplateFile $PSScriptRoot\..\nestedtemplates\storage.json `
	-ContainerName $containerName `
	-SasTokenExpiry $sasTokenExpiry `
	-Verbose

# upload ARM template files to blob storage account
$sa = Get-AzStorageAccount -ResourceGroupName $rgName -Name $storageDeployment.Outputs.storageAccountName.Value
Get-ChildItem $PSScriptRoot\..\nestedtemplates -File | ForEach-Object {
	Set-AzStorageBlobContent `
		-File $_.FullName `
		-Context $sa.Context `
		-Container $containerName `
		-Blob $_.Name `
		-BlobType Block `
		-Force 
}

# deploy key vault to store app gateway ssl certificate 
$keyVaultDeployment = New-AzResourceGroupDeployment `
	-Name "deploy-keyvault" `
	-ResourceGroupName $rg.ResourceGroupName `
	-Mode Incremental `
	-TemplateFile $PSScriptRoot\..\nestedtemplates\keyvault.json `
	-KeyVaultUserObjectId $keyVaultUserObjectId `
	-Verbose

<# 
# base64 encode and upload .pfx ssl certificate to key vault
Set-PfxAsKeyVaultSecret `
	-PfxFile $certFile.FullName `
	-CertificatePassword $certificatePassword `
	-KeyVaultName $keyVaultDeployment.Outputs.keyVaultName.value `
	-Verbose 
#>

$keyVaultDeployment = Get-AzResourceGroupDeployment -ResourceGroupName $rgName -Name 'deploy-keyvault'
$storageDeployment = Get-AzResourceGroupDeployment -ResourceGroupName $rgName -Name 'deploy-storage'
$resourceDeployment = Get-AzResourceGroupDeployment -ResourceGroupName $rgName -Name 'deploy-ase-db'

$templateParams = @{
	storageUri      = $storageDeployment.Outputs.storageContainerUri.value
	sasToken        = $storageDeployment.Outputs.storageAccountSasToken.value
	dbAdminLogin    = 'dbadmin'
	dbAdminPassword = $dbAdminPassword
	aseZones        = @('1', '2')
}

# deploy nsg, vnet, 2 x ase & mySql flexible server, 
$resourceDeployment = New-AzResourceGroupDeployment `
	-Name "deploy-ase-db" `
	-ResourceGroupName $rg.ResourceGroupName `
	-Mode Incremental `
	-TemplateFile $PSScriptRoot\..\azuredeploy-1.json `
	-TemplateParameterFile $PSScriptRoot\..\azuredeploy-1.parameters.json `
	@templateParams `
	-Verbose

# get internal Load Balancer (ILB) App Service Environment (ASE) site fqdns
# create temaplte parameter input array object
$appGwyApp = @{name = 'test-site'; hostName = 'api.kainiindustries.net'; backendAddresses = @(); backends = @(); probePath = '/'; }

$i = 0
while ($i -lt $resourceDeployment.Outputs.aseHostingEnvironmentIds.Value.Count) {
	$appGwyApp.backendAddresses += @{fqdn = $($resourceDeployment.Outputs.siteFqdns.Value[$i].value) }
	$aseId = $resourceDeployment.Outputs.aseHostingEnvironmentIds.Value[$i].value
	$aseIp = az resource show --ids "$aseId/capacities/virtualip" --query internalIpAddress --output tsv --api-version 2018-02-01

	$appGwyApp.backends += @{
		asefqdn   = $($resourceDeployment.Outputs.aseFqdns.Value[$i].value)
		sitename  = $($resourceDeployment.Outputs.siteNames.Value[$i].value)
		asevnetid = $($resourceDeployment.Outputs.aseVnetIds.Value[$i].value)
		ip        = $aseIp
	}

	$i++
}

# create self-signed ssl certificate in key vault
$policy = New-AzKeyVaultCertificatePolicy -ValidityInMonths 12 `
	-SubjectName "CN=$certName" `
	-IssuerName self `
	-RenewAtNumberOfDaysBeforeExpiry 30

$certName = $($certName -replace '\.', '-') + '-1'

Set-AzKeyVaultAccessPolicy -VaultName $keyVaultDeployment.Outputs.keyVaultName.value `
	-EmailAddress $keyVaultUserEmailAddress `
	-PermissionsToCertificates create, get, list

$certificate = Add-AzKeyVaultCertificate -VaultName $keyVaultDeployment.Outputs.keyVaultName.value `
	-Name $certName `
	-CertificatePolicy $policy

$sleepInterval = 5
while ($null -eq ($certificate = Get-AzKeyVaultCertificate -VaultName $keyVaultDeployment.Outputs.keyVaultName.value -Name $certName)) {
	Write-Host "Sleeping '$sleepInterval' seconds until certificate becomes available..."
	Start-Sleep -Seconds $sleepInterval
}

$secretId = $certificate.SecretId.Replace($certificate.Version, "")

$templateParams = @{
	StorageUri         = $storageDeployment.Outputs.storageContainerUri.value
	SasToken           = $storageDeployment.Outputs.storageAccountSasToken.value
	SubnetId           = $resourceDeployment.outputs.appGatewaySubnetId.value
	KeyVaultName       = $keyVaultDeployment.outputs.keyVaultName.value
	AppGwyApplications = $appGwyApp
	CertificateId      = $secretId
}

# deploy application gateway, private DNS zones & DNS records
$appGwyDeployment = New-AzResourceGroupDeployment `
	-Name "deploy-app-gateway" `
	-ResourceGroupName $rg.ResourceGroupName `
	-Mode Incremental `
	-TemplateFile $PSScriptRoot\..\azuredeploy-2.json `
	-TemplateParameterFile $PSScriptRoot\..\azuredeploy-2.parameters.json `
	@templateParams `
	-Verbose
