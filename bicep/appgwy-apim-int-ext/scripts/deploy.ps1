$password = 'M1cr0soft123'
$location = 'westus2'
$rgName = "apim-appgwy-func-$location-rg"
$certArr = @()
$cloudInitData = $(Get-Content ./cloud-init.txt -Raw)

# https://github.com/MicrosoftDocs/azure-docs/issues/61561

foreach ($pfxCert in $(Get-ChildItem -Path ../certs -File -Filter *.pfx)) {
    $pfx = Get-PfxData -FilePath $pfxCert.Fullname -Password $password
    Export-PfxCertificate -CryptoAlgorithmOption TripleDES_SHA1 -Password $password -PfxData $pfx
    <# $flag = [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::Exportable
    $collection = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2Collection
    $collection.Import($pfxCert.FullName, $password, $flag)
    $pkcs12ContentType = [System.Security.Cryptography.X509Certificates.X509ContentType]::Pkcs12
    $clearBytes = $collection.Export($pkcs12ContentType, $password)
    $fileContentEncoded = [System.Convert]::ToBase64String($clearBytes) #>
    $certArr += @{CertName = $pfxCert.BaseName; CertValue = $fileContentEncoded; CertPassword = $password}
}

$rg = New-AzResourceGroup -Name $rgName -Location $location -Force

New-AzResourceGroupDeployment `
    -Name 'apim-app-gwy-test-deploy' `
    -ResourceGroupName $rg.ResourceGroupName `
    -Mode Incremental `
    -TemplateFile ../main.bicep `
    -TemplateParameterFile ../main.parameters.json `
    -Location $location `
    -Secrets $certArr `
    -CustomData $cloudInitData `
    -Verbose
