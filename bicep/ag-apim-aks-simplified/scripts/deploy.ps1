Param (
    [string]$Location = 'australiaeast',
    [string]$AADTenant = 'kainiindustries.net',
    [string]$PublicDnsZone = 'kainiindustries.net',
    [string]$PublicDnsZoneResourceGroup = 'external-dns-zones-rg',
    [string]$Prefix = 'demo',
    [string]$PfxCertificateName = 'star.kainiindustries.net.pfx',
    [string]$CertificateName = 'star.kainiindustries.net.cer',
    [SecureString]$CertificatePassword = $('M1cr0soft1234567890' | ConvertTo-SecureString -AsPlainText -Force),
    [string]$AksAdminGroupObjectId = "f6a900e2-df11-43e7-ba3e-22be99d3cede",
    [string]$ResourceGroupName = "ag-apim-aks-$Location-simple-2-rg",
    [string]$ReactSpaSvcIp = '2.2.2.2'
)

$deploymentName = 'ag-apim-aks-deploy'
$keyVaultDeploymentName = 'kv-deploy'

$ErrorActionPreference = 'stop'

# create resource group
$rg = New-AzResourceGroup -Name $ResourceGroupName -Location $Location -Force

# create key vault & upload SSL certificate
Write-Host -Object "Deploying Key Vault"
New-AzResourceGroupDeployment `
    -Name $keyVaultDeploymentName `
    -ResourceGroupName $rg.ResourceGroupName `
    -Mode Incremental `
    -templateFile ../infra/modules/keyvault.bicep `
    -keyVaultAdminObjectId $(Get-AzADUser -SignedIn | Select-Object -ExpandProperty Id) `
    -location $Location `
    -deployUserAccessPolicy $false

# get deployment output
$kvDeployment = Get-AzResourceGroupDeployment -Name $keyVaultDeploymentName -ResourceGroupName $rg.ResourceGroupName

# upload public tls certificate to Key Vault
Write-Host -Object "Uploading TLS certificate to Key Vault"
$tlsCertificate = Import-AzKeyVaultCertificate -VaultName $kvDeployment.Outputs.keyVaultName.value `
    -Name 'public-tls-certificate' `
    -Password $CertificatePassword `
    -FilePath ../certs/$PfxCertificateName

# deploy bicep template
Write-Host -Object "Deploying infrastructure"
New-AzResourceGroupDeployment `
    -Name $deploymentName `
    -ResourceGroupName $rg.ResourceGroupName `
    -TemplateParameterFile  ../infra/main.parameters.json `
    -Mode Incremental `
    -templateFile ../infra/main.bicep `
    -location $Location `
    -publicDnsZoneName $PublicDnsZone `
    -publicDnsZoneResourceGroup $PublicDnsZoneResourceGroup `
    -privateDnsZoneName "internal.$PublicDnsZone" `
    -aksAdminGroupObjectId $AksAdminGroupObjectId `
    -kubernetesSpaIpAddress $reactSpaSvcIp `
    -keyVaultName $kvDeployment.Outputs.keyVaultName.value `
    -tlsCertSecretId $($tlsCertificate.SecretId | ConvertTo-SecureString -AsPlainText -Force) `
    -Verbose

# get deployment output
$deployment = Get-AzResourceGroupDeployment -Name $deploymentName -ResourceGroupName $rg.ResourceGroupName

# stop & start the app gateway for it to get the updated DNS zone!!!!
$appgwy = Get-AzApplicationGateway -Name $deployment.Outputs.appGwyName.value -ResourceGroupName $rg.ResourceGroupName

Write-Host -Object "Stopping App Gateway"
Stop-AzApplicationGateway -ApplicationGateway $appgwy

Write-Host -Object "Starting App Gateway"
Start-AzApplicationGateway -ApplicationGateway $appgwy


<# $ErrorActionPreference="Stop"
Login-AzureRmAccount -SubscriptionId b2375b5f-8dab-4436-b87c-32bc7fdce5d0
$spn=(Get-AzADServicePrincipal -SPN 13557c92-19a6-4b65-8b85-8733efafb445)
$spnObjectId=$spn.Id
Set-AzKeyVaultAccessPolicy -VaultName ag-apim-aks-kv -ObjectId $spnObjectId -PermissionsToSecrets get,list #>