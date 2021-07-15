$pwd = 'M1cr0soft123' | ConvertTo-SecureString -AsPlainText -Force

$rootCert = New-SelfSignedCertificate -CertStoreLocation cert:\CurrentUser\My -DnsName "KainiIndustries CA" -KeyUsage CertSign
Export-Certificate -Cert $rootcert -FilePath ..\certs\rootCA.cer

$sslCert = New-SelfSignedCertificate -certstorelocation cert:\LocalMachine\My -dnsname api.kainiindustries.net -Signer $rootCert
Export-PfxCertificate -cert $sslCert -FilePath ..\certs\sslCert.pfx -Password $pwd -CryptoAlgorithmOption TripleDES_SHA1
