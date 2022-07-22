$password = 'M1cr0soft1234567890'
$location = 'australiaeast'
$domainName = 'aksdemo.kainiindustries.net'
$rgName = "ag-apim-aks-$location-rg"
$aksAdminGroupObjectId = 'f6a900e2-df11-43e7-ba3e-22be99d3cede'
$sans = "api.$domainName", "portal.$domainName", "management.$domainName", "proxy.internal.$domainName", "portal.internal.$domainName", "management.internal.$domainName"
$sshPublicKey = $(cat ~/.ssh/id_rsa.pub)
$pkcs12ContentType = [System.Security.Cryptography.X509Certificates.X509ContentType]::Pkcs12 
$cerContentType = [System.Security.Cryptography.X509Certificates.X509ContentType]::Cert
$cert = @{}
$root = @{}

if (!($rootCert = $(Get-ChildItem Cert:\CurrentUser\my | Where-Object { $_.friendlyName -eq 'KainiIndustries Root CA Certificate' }))) {
    Write-Host "Creating new Self-Signed CA Certificate"
    $rootCert = New-SelfSignedCertificate -CertStoreLocation 'cert:\CurrentUser\My' -TextExtension @("2.5.29.19={text}CA=true") -DnsName 'KainiIndustries CA' -Subject "SN=KainiIndustriesRootCA" -KeyUsageProperty All -KeyUsage CertSign, CRLSign, DigitalSignature -FriendlyName 'KainiIndustries Root CA Certificate'
}

$clearBytes = $rootCert.Export($cerContentType)
$fileContentEncoded = [System.Convert]::ToBase64String($clearBytes)
$root = @{CertName = $rootCert.Thumbprint; CertValue = $fileContentEncoded; CertPassword = $password }

if (!($pfxCert = $(Get-ChildItem Cert:\CurrentUser\my | Where-Object { $_.friendlyName -eq 'KainiIndustries Client Certificate' }))) {
    Write-Host "Creating new Self-Signed Client Certificate"
    $pfxCert = New-SelfSignedCertificate -certstorelocation 'cert:\CurrentUser\My' -dnsname $sans -Signer $rootCert -FriendlyName 'KainiIndustries Client Certificate'
}

$clearBytes = $pfxCert.Export($pkcs12ContentType, $password)
$fileContentEncoded = [System.Convert]::ToBase64String($clearBytes)
$cert = @{CertName = $pfxCert.Thumbprint; CertValue = $fileContentEncoded; CertPassword = $password }

# deploy bicep templates
$rg = New-AzResourceGroup -Name $rgName -Location $location -Force

New-AzResourceGroupDeployment `
    -Name 'ag-apim-aks-deploy' `
    -ResourceGroupName $rg.ResourceGroupName `
    -TemplateParameterFile  ../main.parameters.json `
    -Mode Incremental `
    -templateFile ../main.bicep `
    -location $location `
    -domainName $domainName `
    -cert $cert `
    -rootCert $root `
    -sshPublicKey $sshPublicKey `
    -winVmPassword $password `
    -aksAdminGroupObjectId $aksAdminGroupObjectId `
    -Verbose

$deployment = Get-AzResourceGroupDeployment -Name 'ag-apim-aks-deploy' -ResourceGroupName $rg.ResourceGroupName

# allow AKS to access ACR
Set-AzAksCluster -Name $deployment.Outputs.aksClusterName.value `
    -ResourceGroupName $rg.ResourceGroupName `
    -AcrNameToAttach $deployment.Outputs.acrName.value

# stop & start the app gateway for it to get the updated DNS zone!!!!
$appgwy = Get-AzApplicationGateway -Name $deployment.Outputs.appGwyName.value -ResourceGroupName $rg.ResourceGroupName
Stop-AzApplicationGateway -ApplicationGateway $appgw
Start-AzApplicationGateway -ApplicationGateway $appgw

# or CLI
# az network application-gateway stop -n $deployment.Outputs.appGwyName.value  -g $rg.ResourceGroupName
# az network application-gateway start -n $deployment.Outputs.appGwyName.value  -g $rg.ResourceGroupName

# test api endpoints
curl -k https://api.aksdemo.kainiindustries.net/order-api/orders
curl -k https://api.aksdemo.kainiindustries.net/product-api/products

<# 
# import api from OpenApi definition
$apimContext = New-AzApiManagementContext -ResourceGroupName $rg.ResourceGroupName -ServiceName $deployment.Outputs.apimName.Value

if ($null -eq (Get-AzApiManagementApi -Context $apimContext -Name $apiName)) {
    Import-AzApiManagementApi -Context $apimContext `
        -ApiId $apiName `
        -SpecificationFormat OpenApi `
        -SpecificationPath ../api/api.yaml `
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
 #>