$pfxCerts = Get-ChildItem -Path ../certs -Filter *.pfx
$password = ""

foreach ($pfxCert in $PfxCerts) {
    $flag = [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::Exportable
    $collection = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2Collection
    $collection.Import($pfxCert.FullName, $password, $flag)
    $pkcs12ContentType = [System.Security.Cryptography.X509Certificates.X509ContentType]::Pkcs12
    $clearBytes = $collection.Export($pkcs12ContentType)
    $fileContentEncoded = [System.Convert]::ToBase64String($clearBytes)
    @{
        'name'   = $pfxCert.Name
        'base64' = $fileContentEncoded
    }
}

