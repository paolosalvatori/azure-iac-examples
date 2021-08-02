$password = 'M1cr0soft123'
$location = 'westus2'
$rgName = "apim-appgwy-func-$location-rg"

# create certificate chain
$securePassword = $password | ConvertTo-SecureString -AsPlainText -Force

$rootCert = New-SelfSignedCertificate -CertStoreLocation 'cert:\CurrentUser\My' -DnsName 'KainiIndustries CA' -KeyUsage CertSign
Export-Certificate -Cert $rootcert -FilePath ..\certs\rootCA.cer

$sslCert = New-SelfSignedCertificate -certstorelocation 'cert:\LocalMachine\My' -dnsname 'api.kainiindustries.net' -Signer $rootCert
Export-PfxCertificate -cert $sslCert -FilePath ..\certs\sslCert.pfx -Password $securePassword -CryptoAlgorithmOption TripleDES_SHA1

# create Base64 encoded versions of the root & client certificates
foreach ($pfxCert in $(Get-ChildItem -Path ../certs -File -Filter *.pfx)) {
    $flag = [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::Exportable
    $collection = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2Collection
    $collection.Import($pfxCert.FullName, $password, $flag)

    foreach ($cert in $collection) {
        if ($cert.HasPrivateKey) {
            $pkcs12ContentType = [System.Security.Cryptography.X509Certificates.X509ContentType]::Pkcs12
            $clearBytes = $cert.Export($pkcs12ContentType, $password)
            $fileContentEncoded = [System.Convert]::ToBase64String($clearBytes)
            $cert = @{CertName = $cert.Thumbprint; CertValue = $fileContentEncoded; CertPassword = $password}
        } else {
            $cerContentType = [System.Security.Cryptography.X509Certificates.X509ContentType]::Cert
            $clearBytes = $cert.Export($cerContentType, $password)
            $fileContentEncoded = [System.Convert]::ToBase64String($clearBytes)
            $rootCert = @{CertName = $cert.Thumbprint; CertValue = $fileContentEncoded; CertPassword = $password}
        }
    }
}

<<<<<<< HEAD
az bicep build --file ../main.bicep
=======
$clientAppPassword = '234jk234rjkfg53oi34fonfl4'
$apiAppPassword = 'BzTFC8hKb5epmHadPbrf57~M~_u9.i11d3'

# create backend Application Registration
$todoApiApp = az ad app create --display-name todo-api --app-roles ./appRoleManifest.json --password $clientAppPassword | ConvertFrom-Json
# must be set manually via 'Manifest' json or az rest
# az ad app update --id $todoApiApp.appId --set accessTokenAcceptedVersion=2
az ad sp create --id $todoApiApp.appId

# create client Application registration
$todoApiClientApp = az ad app create --display-name todo-api-client --password $clientAppPassword | ConvertFrom-Json
# must be set manually via 'Manifest' json or az rest
# az ad app update --id $todoApiClientApp.appId --set accessTokenAcceptedVersion=2  
az ad sp create --id $todoApiClientApp.appId

# az ad app permission add --api-permissions 311a71cc-e848-46a1-bdf8-97ff7156d8e6=Scope
az ad app permission grant --id $todoApiClientApp.appId --api $todoApiApp.appId --scope Api.Caller

$todoApiApp
$todoApiClientApp

# az bicep build --file ../main.bicep
>>>>>>> 5a46e9df023a6f1b9f6d9b9a11d6f9bbb0615a4b

$rg = New-AzResourceGroup -Name $rgName -Location $location -Force

<# New-AzResourceGroupDeployment `
    -Name 'apim-app-gwy-test-deploy' `
    -ResourceGroupName $rg.ResourceGroupName `
    -Mode Incremental `
    -TemplateFile ../main.json `
    -TemplateParameterFile ../main.parameters.json `
    -Location $location `
    -Cert $cert `
    -RootCert $rootCert `
    -Verbose
 #>