$rgName = 'vmss-demo-1'
$adminPassword = 'M1cr0soft123'
$certPassword = 'M1cr0soft123'
$location = 'australiaeast'
$deploymentName = 'infra-deployment'
$hostname = 'myapp.kainiindustries.net'
$sshPublicKey = $(Get-Content $home/.ssh/id_rsa.pub -Raw)
$vmssCustomScriptUri = 'https://stor3478ge8w7934.blob.core.windows.net/scripts/install.sh'
$adminUsername = 'localadmin'
$vmssInstanceCount = 3

if (!($rootCert = $(Get-ChildItem Cert:\CurrentUser\my | Where-Object { $_.friendlyName -eq 'KainiIndustries Root CA Certificate' }))) {
    Write-Host "Creating new Self-Signed CA Certificate"
    $rootCert = New-SelfSignedCertificate -CertStoreLocation 'cert:\CurrentUser\My' -TextExtension @("2.5.29.19={text}CA=true") -DnsName 'KainiIndustries CA' -Subject "SN=KainiIndustriesRootCA" -KeyUsageProperty All -KeyUsage CertSign, CRLSign, DigitalSignature -FriendlyName 'KainiIndustries Root CA Certificate'
    Export-Certificate -Cert $rootcert -FilePath ..\certs\rootCert.cer -Force
}

if (!($cert = $(Get-ChildItem Cert:\CurrentUser\my | Where-Object { $_.friendlyName -eq 'KainiIndustries Client Certififcate' }))) {
    Write-Host "Creating new Self-Signed Client Certificate"
    $pkcs12ContentType = [System.Security.Cryptography.X509Certificates.X509ContentType]::Pkcs12
    $cert = New-SelfSignedCertificate -certstorelocation 'cert:\CurrentUser\My' -dnsname $hostname -Signer $rootCert -FriendlyName 'KainiIndustries Client Certififcate'
    $clearBytes = $cert.Export($pkcs12ContentType, $certPassword)
    $fileContentEncoded = [System.Convert]::ToBase64String($clearBytes)
    $pfxCert = @{name = $cert.Thumbprint; value = $fileContentEncoded; password = $certPassword }
    Export-PfxCertificate -cert $cert -FilePath ..\certs\clientCert.pfx -Password $($certPassword | ConvertTo-SecureString -AsPlainText -Force) -CryptoAlgorithmOption TripleDES_SHA1 -Force
}
else {
    $pkcs12ContentType = [System.Security.Cryptography.X509Certificates.X509ContentType]::Pkcs12
    $clearBytes = $cert.Export($pkcs12ContentType, $certPassword)
    $fileContentEncoded = [System.Convert]::ToBase64String($clearBytes)
    $pfxCert = @{name = $cert.Thumbprint; value = $fileContentEncoded; password = $certPassword }
    Export-PfxCertificate -cert $cert -FilePath ..\certs\clientCert.pfx -Password $($certPassword | ConvertTo-SecureString -AsPlainText -Force) -CryptoAlgorithmOption TripleDES_SHA1 -Force
}

az group create --name $rgName --location $location

az deployment group create `
    --name $deploymentName `
    --resource-group $rgName `
    --template-file ./main.bicep `
    --parameters adminUsername=$adminUsername `
    --parameters adminPassword=$adminPassword `
    --parameters pfxCert=$($pfxCert.value) `
    --parameters pfxCertPassword=$($pfxCert.password) `
    --parameters appGwyHostName=$hostName `
    --parameters vmssInstanceCount=$vmssInstanceCount `
    --parameters vmssCustomScriptUri=$vmssCustomScriptUri `
    --parameters sshPublicKey=$sshPublicKey

