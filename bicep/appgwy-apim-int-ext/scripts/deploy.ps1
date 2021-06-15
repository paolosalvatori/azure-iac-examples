$password = ""
$location = 'australiaeast'
$rgName = "apim-app-gwy-$location-rg"
$certArr = @()

foreach ($pfxCert in $(Get-ChildItem -Path ../certs -Filter *.pfx)) {
    $flag = [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::Exportable
    $collection = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2Collection
    $collection.Import($pfxCert.FullName, $password, $flag)
    $pkcs12ContentType = [System.Security.Cryptography.X509Certificates.X509ContentType]::Pkcs12
    $clearBytes = $collection.Export($pkcs12ContentType)
    $fileContentEncoded = [System.Convert]::ToBase64String($clearBytes)
    $certArr += @{CertName = $pfxCert.BaseName; CertValue = $fileContentEncoded}
}

az bicep build --f ../main.bicep

$rg = New-AzResourceGroup -Name $rgName -Location $location -Force

New-AzResourceGroupDeployment `
    -Name 'apim-app-gwy-test-deploy' `
    -ResourceGroupName $rg.ResourceGroupName `
    -Mode Incremental `
    -TemplateFile ../main.json `
    -TemplateParameterFile ../main.parameters.json `
    -Location $location `
    -Secrets $certArr

<# $deployment = Get-AzResourceGroupDeployment -ResourceGroupName $rg.ResourceGroupName -Name 'apim-app-gwy-test-deploy'
$appGwyId = $deployment.Outputs.appGwyId.value
$zone = Get-AzDnsZone -ResourceGroupName 'external-dns-zones-rg' -Name 'kainiindustries.net'
New-AzDnsRecordSet -Name 'api' -TargetResourceId $appGwyId -Zone $zone -Ttl 3600 -RecordType CNAME
 #>