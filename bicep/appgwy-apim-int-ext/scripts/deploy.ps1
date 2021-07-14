$password = 'M1cr0soft123'
$location = 'westus2'
$rgName = "apim-appgwy-func-$location-rg"
$certArr = @()
$rootCertArr = @()
$cloudInitData = $(Get-Content ./cloud-init.txt -Raw)

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

$rg = New-AzResourceGroup -Name $rgName -Location $location -Force

New-AzResourceGroupDeployment `
    -Name 'apim-app-gwy-test-deploy' `
    -ResourceGroupName $rg.ResourceGroupName `
    -Mode Incremental `
    -TemplateFile ../main.bicep `
    -TemplateParameterFile ../main.parameters.json `
    -Location $location `
    -Cert $cert `
    -RootCert $rootCert `
    -Verbose
