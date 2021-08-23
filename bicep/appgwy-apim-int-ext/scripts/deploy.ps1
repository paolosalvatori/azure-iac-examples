$certPassword = 'M1cr0soft123'
$location = 'westus2'
$domainName = 'kainiindustries.net'
$rgName = "ag-apim-td-api-$location-rg"
$sans = "api.$domainName", "portal.$domainName", "management.$domainName", "proxy.internal.$domainName", "portal.internal.$domainName", "management.internal.$domainName"
$blobName = 'funcapp.zip'
$winVmPassword = 'M1cr0soft1234567890'
$appName = 'todo-api-func'
$apiName = 'todo-api'
$tags = @{
    'costcenter'='123456789'
    'environment'='devtest'
}

# create app registration for function app
if ((az ad sp list --all --query "[?displayName=='$appName']" | ConvertFrom-Json).Length -le 0) {
    "Creating App Registration '$appName'"
    $sp = az ad sp create-for-rbac --name $appName | ConvertFrom-Json
    az ad app update --id $sp.appId --app-roles `@role.json
} else {
    $sp = az ad sp list --all --query "[?displayName=='$appName']" | ConvertFrom-Json
    az ad sp update --id $sp.objectId --set appRoleAssignmentRequired=True
}

# create certificate chain
$securePassword = $certPassword | ConvertTo-SecureString -AsPlainText -Force

if (!($rootCert = $(Get-ChildItem Cert:\CurrentUser\my | Where-Object { $_.friendlyName -eq 'KainiIndustries Root CA Certificate' }))) {
    Write-Host "Creating new Self-Signed CA Certificate"
    $rootCert = New-SelfSignedCertificate -CertStoreLocation 'cert:\CurrentUser\My' -TextExtension @("2.5.29.19={text}CA=true") -DnsName 'KainiIndustries CA' -Subject "SN=KainiIndustriesRootCA" -KeyUsageProperty All -KeyUsage CertSign, CRLSign, DigitalSignature -FriendlyName 'KainiIndustries Root CA Certificate'
    Export-Certificate -Cert $rootcert -FilePath ..\certs\rootCert.cer -Force
}

if (!($pfxCert = $(Get-ChildItem Cert:\CurrentUser\my | Where-Object { $_.friendlyName -eq 'KainiIndustries Client Certififcate' }))) {
    Write-Host "Creating new Self-Signed Client Certificate"
    $pfxCert = New-SelfSignedCertificate -certstorelocation 'cert:\CurrentUser\My' -dnsname $sans -Signer $rootCert -FriendlyName 'KainiIndustries Client Certififcate'
    Export-PfxCertificate -cert $pfxCert -FilePath ..\certs\clientCert.pfx -Password $securePassword -CryptoAlgorithmOption TripleDES_SHA1 -Force
}

# create Base64 encoded versions of the root & client certificates
foreach ($pfxCert in $(Get-ChildItem -Path ../certs -File -Filter *.pfx)) {
    $flag = [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::Exportable
    $collection = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2Collection
    $collection.Import($pfxCert.FullName, $certPassword, $flag)

    foreach ($cert in $collection) {
        $cert
        if ($cert.HasPrivateKey) {
            $pkcs12ContentType = [System.Security.Cryptography.X509Certificates.X509ContentType]::Pkcs12
            $clearBytes = $cert.Export($pkcs12ContentType, $certPassword)
            $fileContentEncoded = [System.Convert]::ToBase64String($clearBytes)
            $cert = @{CertName = $cert.Thumbprint; CertValue = $fileContentEncoded; CertPassword = $certPassword }
        }
        else {
            $cerContentType = [System.Security.Cryptography.X509Certificates.X509ContentType]::Cert
            $clearBytes = $cert.Export($cerContentType, $certPassword)
            $fileContentEncoded = [System.Convert]::ToBase64String($clearBytes)
            $rootCert = @{CertName = $cert.Thumbprint; CertValue = $fileContentEncoded; CertPassword = $certPassword }
        }
    }
}

# deploy bicep templates
$rg = New-AzResourceGroup -Name $rgName -Location $location -Force

New-AzResourceGroupDeployment `
    -Name 'apim-app-gwy-deploy' `
    -ResourceGroupName $rg.ResourceGroupName `
    -Mode Incremental `
    -TemplateFile ../main.bicep `
    -Location $location `
    -DomainName $domainName `
    -Tags $tags `
    -Cert $cert `
    -RootCert $rootCert `
    -WinVmPassword $winVmPassword `
    -FunctionAppId $sp.appId `
    -Verbose

$deployment = Get-AzResourceGroupDeployment -ResourceGroupName $rg.ResourceGroupName -Name 'apim-app-gwy-deploy'

# compress funtion app code to .zip file
Compress-Archive -Path ../api/* -DestinationPath ./$blobName -Update

# deploy web app code as zip file
az webapp deployment source config-zip --resource-group $rg.ResourceGroupName --name $deployment.Outputs.funcAppName.Value --src ./$blobName

# import api from OpenApi definition
$apimContext = New-AzApiManagementContext -ResourceGroupName $rg.ResourceGroupName -ServiceName $deployment.Outputs.apimName.Value

if ($null -eq (Get-AzApiManagementApi -Context $apimContext -Name $apiName)) {
Import-AzApiManagementApi -Context $apimContext `
    -ApiId $apiName `
    -SpecificationFormat OpenApi `
    -SpecificationPath ../api/api.yml `
    -Path 'external' `
    -Protocol Https `
    -ServiceUrl $deployment.Outputs.funcAppUri.Value `
    -ApiType Http
}

# disable subscription requirement
$api = Get-AzApiManagementApi -Context $apimContext -Name $apiName
$api.SubscriptionRequired = $false
Set-AzApiManagementApi -InputObject $api -Name $api.Name -ServiceUrl $api.ServiceUrl -Protocols $api.Protocols

# add managed identity authnetication policy
$policyBody = "<policies><inbound><base /><authentication-managed-identity resource='$($sp.appId)'/></inbound><backend><base /></backend><outbound><base /></outbound><on-error><base /></on-error></policies>"
Set-AzApiManagementPolicy -Context $apimContext -ApiId $api.ApiId -Policy $policyBody -Verbose

# add the API Management Managed Identity to the funcion app's  'Todo.User' app role
# this will allow only the APIM Managed Identity to call the function app
az ad sp update --id $sp.objectId --set appRoleAssignmentRequired=True
$appObjectId = az ad sp show --id $sp.appid --query "objectId" -o tsv
 
@"
{"principalId":"$($deployment.Outputs.apimManagedIdentity.Value)","resourceId":"$appObjectId","appRoleId":"$($sp.appRoles[0].id)"}
"@ > ./body.json

az rest `
--method POST `
--uri "https://graph.microsoft.com/v1.0/servicePrincipals/$($deployment.Outputs.apimManagedIdentity.Value)/appRoleAssignments" `
--headers 'Content-Type=application/json' --body "@body.json"
