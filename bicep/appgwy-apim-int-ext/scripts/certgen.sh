PASSWORD='M1cr0soft123'

# generate app gateway self-signed certificate
openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 -keyout ../certs/appgwy.private.key -out ../certs/appgwy.crt \
-subj "/C=AU/ST=NSW/L=Sydney/O=KainiIndustries, Inc./OU=IT/CN=www.kainiindustries.net"

openssl pkcs12 -export -out ../certs/appgwy.pfx -inkey ../certs/appgwy.private.key -in ../certs/appgwy.crt \
-passout pass:$PASSWORD 

# create APIM self-signed certificates
openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 -keyout ../certs/apimapi.private.key -out ../certs/apimapi.crt \
-subj "/C=AU/ST=NSW/L=Sydney/O=KainiIndustries, Inc./OU=IT/CN=api.kainiindustries.net"

# generate .pfx file
openssl pkcs12 -export -out ../certs/apimapi.pfx -inkey ../certs/apimapi.private.key -in ../certs/apimapi.crt \
-passout pass:$PASSWORD
