$password = 'M1cr0soft123'
$location = 'westus2'
$rgName = "apim-appgwy-cbellee-$location-rg"
$sans = 'api.kainiindustries.net', 'apim.kainiindustries.net', 'api.internal.kainiindustries.net', 'apim.internal.kainiindustries.net'
$containerName = 'app'
$blobName = 'funcapp.zip'
$packageStorageAccountName = 'cbelleepackagestor579821'
$winVmPassword = 'M1cr0soft1234567890'

# create certificate chain
$securePassword = $password | ConvertTo-SecureString -AsPlainText -Force

if (!($rootCert = $(Get-ChildItem Cert:\CurrentUser\my | Where-Object { $_.friendlyName -eq 'KainiIndustries Root CA Certificate' }))) {
    Write-Host "Creating new Self-Signed CA Certificate"
    $rootCert = New-SelfSignedCertificate -CertStoreLocation 'cert:\CurrentUser\My' -TextExtension @("2.5.29.19={text}CA=true") -DnsName 'KainiIndustries CA' -Subject "SN=KainiIndustriesRootCA" -KeyUsageProperty All -KeyUsage CertSign, CRLSign, DigitalSignature -FriendlyName 'KainiIndustries Root CA Certificate'
}
Export-Certificate -Cert $rootcert -FilePath ..\certs\rootCert.cer -Force

if (!($pfxCert = $(Get-ChildItem Cert:\CurrentUser\my | Where-Object { $_.friendlyName -eq 'KainiIndustries Client Certififcate' }))) {
    Write-Host "Creating new Self-Signed Client Certificate"
    $pfxCert = New-SelfSignedCertificate -certstorelocation 'cert:\CurrentUser\My' -dnsname $sans -Signer $rootCert -FriendlyName 'KainiIndustries Client Certififcate'
}
Export-PfxCertificate -cert $pfxCert -FilePath ..\certs\clientCert.pfx -Password $securePassword -CryptoAlgorithmOption TripleDES_SHA1 -Force

# create Base64 encoded versions of the root & client certificates
foreach ($pfxCert in $(Get-ChildItem -Path ../certs -File -Filter *.pfx)) {
    $flag = [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::Exportable
    $collection = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2Collection
    $collection.Import($pfxCert.FullName, $password, $flag)

    foreach ($cert in $collection) {
        $cert
        if ($cert.HasPrivateKey) {
            $pkcs12ContentType = [System.Security.Cryptography.X509Certificates.X509ContentType]::Pkcs12
            $clearBytes = $cert.Export($pkcs12ContentType, $password)
            $fileContentEncoded = [System.Convert]::ToBase64String($clearBytes)
            $cert = @{CertName = $cert.Thumbprint; CertValue = $fileContentEncoded; CertPassword = $password }
        }
        else {
            $cerContentType = [System.Security.Cryptography.X509Certificates.X509ContentType]::Cert
            $clearBytes = $cert.Export($cerContentType, $password)
            $fileContentEncoded = [System.Convert]::ToBase64String($clearBytes)
            $rootCert = @{CertName = $cert.Thumbprint; CertValue = $fileContentEncoded; CertPassword = $password }
        }
    }
}

$rg = New-AzResourceGroup -Name $rgName -Location $location -Force

# compress funtion app code to .zip file
Compress-Archive -Path ../api/* -DestinationPath ./$blobName -Update

# create sotrage account & container, then upload the .zip file
if (!($packageStore=$(Get-AzStorageAccount -ResourceGroupName $rgName -Name $packageStorageAccountName))) {
$packageStore = New-AzStorageAccount `
    -ResourceGroupName $rgName `
    -SkuName 'Standard_LRS' `
    -Name $packageStorageAccountName `
    -Location $location `
    -Kind 'Storagev2' `
    -AccessTier Hot

New-AzStorageContainer -Name $containerName -Context $packageStore.Context
}

Set-AzStorageBlobContent `
    -File ./$blobName `
    -Container $containerName `
    -Blob $blobName `
    -Context $packageStore.Context `
    -Force

$expiry = (Get-Date).AddHours(2)
$blobSasUrl = New-AzStorageBlobSASToken `
    -Container $containerName `
    -Context $packageStore.Context `
    -Blob $blobName `
    -ExpiryTime $expiry `
    -Permission r `
    -FullUri

curl -X POST -u cbellee --data-binary @<zipfile> https://{your-sitename}.scm.azurewebsites.net/api/zipdeploy

New-AzResourceGroupDeployment `
    -Name 'apim-app-gwy-deploy' `
    -ResourceGroupName $rg.ResourceGroupName `
    -Mode Incremental `
    -TemplateFile ../main.bicep `
    -TemplateParameterFile ../main.parameters.json `
    -Location $location `
    -Cert $cert `
    -RootCert $rootCert `
    -WinVmPassword $winVmPassword `
    -FuncAppPackageUrl $blobSasUrl `
    -Verbose
