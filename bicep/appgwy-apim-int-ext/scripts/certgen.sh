# generate .pfx files
openssl pkcs12 -export -out ../certs/api.pfx -inkey ../certs/api.private.key -in ../certs/api.certificate.crt
openssl pkcs12 -export -out ../certs/portal.pfx -inkey ../certs/portal.private.key -in ../certs/portal.certificate.crt

# generate .cer files
openssl x509 -inform pem -in ../certs/api.certificate.crt -outform der -out ../certs/api.cer
openssl x509 -inform pem -in ../certs/portal.certificate.crt -outform der -out ../certs/portal.cer
