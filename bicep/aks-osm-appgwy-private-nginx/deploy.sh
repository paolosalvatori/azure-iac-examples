LOCATION='australiaeast'
SSH_KEY=$(cat ~/.ssh/id_rsa.pub)
ADMIN_GROUP_OBJECT_ID="f6a900e2-df11-43e7-ba3e-22be99d3cede"
LATEST_K8S_VERSION=$(az aks get-versions -l $LOCATION | jq -r -c '[.orchestrators[] | .orchestratorVersion][-1]')
PREFIX='aks-osm-appgwy-nginx'
RG_NAME="$PREFIX-rg"
SSH_KEY=$(cat ~/.ssh/id_rsa.pub)
PUBLIC_DNS_ZONE_RG_NAME='external-dns-zones-rg'

PUBLIC_PFX_CERT_FILE='./certs/star.kainiindustries.net.bundle.pfx'
PUBLIC_PFX_CERT_NAME='star-kainiindustries-net-pfx'
PRIVATE_KEY_FILE='./certs/key.pem'
PRIVATE_CERT_FILE='./certs/cert.crt'
PRIVATE_CERT_KEY_FILE='./certs/key.pem'
PRIVATE_CERT_NAME='internal-nginx-kainiindustries-net'
PRIVATE_PFX_CERT_FILE='./certs/internal-nginx-kainiindustries-net.pfx'

INTERNAL_HOST_NAME='internal.nginx.kainiindustries.net'
INGRESS_PRIVATE_IP=$(cat ./manifests/internal-ingress.yaml | grep -oE "\b[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}")

source ./.env

# create TLS certificate for NGINX 
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout ${PRIVATE_KEY_FILE} -out ${PRIVATE_CERT_FILE} -subj "/CN=${INTERNAL_HOST_NAME}/O=${INTERNAL_HOST_NAME}" -addext "subjectAltName = DNS:${INTERNAL_HOST_NAME}"

# convert TLS certificate to PFX format
openssl pkcs12 -export -out $PRIVATE_PFX_CERT_FILE -inkey $PRIVATE_KEY_FILE -in $PRIVATE_CERT_FILE

# convert Public bundle.pem to .pfx
# openssl pkcs12 -export -out star.kainiindustries.net.bundle.pfx -inkey your_private.key -in your_pem_certificate.crt -certfile CA-bundle.crt

# create resource group
az group create --location $LOCATION --name $RG_NAME

# deploy key vault
az deployment group create \
    --resource-group $RG_NAME \
    --name kv-deployment \
    --template-file ./modules/keyvault.bicep \
    --parameters keyVaultAdminObjectId=$ADMIN_GROUP_OBJECT_ID \
    --parameters location=$LOCATION

KV_NAME=$(az deployment group show --resource-group $RG_NAME --name kv-deployment --query 'properties.outputs.keyVaultName.value' -o tsv)

# upload public tls certificate to Key Vault
PFX_CERT_PROPS=$(az keyvault certificate import --vault-name $KV_NAME -n $PUBLIC_PFX_CERT_NAME -f $PUBLIC_PFX_CERT_FILE --password $PFX_CERT_PASSWORD)
PFX_CERT_ID=$(echo $PFX_CERT_PROPS | jq .id -r)
PFX_CERT_SID=$(echo $PFX_CERT_PROPS | jq .sid -r)
PFX_CERT_KID=$(echo $PFX_CERT_PROPS | jq .kid -r)
PFX_CERT_CER=$(echo $PFX_CERT_PROPS | jq .cer -r)

# upload backend trusted root tls certificate to Key Vault
CERT_PROPS=$(az keyvault certificate import --vault-name $KV_NAME -n $PRIVATE_CERT_NAME -f $PRIVATE_PFX_CERT_FILE)
CERT_ID=$(echo $CERT_PROPS | jq .id -r)
CERT_SID=$(echo $CERT_PROPS | jq .sid -r)
CERT_KID=$(echo $CERT_PROPS | jq .kid -r)
CERT_CER=$(echo $CERT_PROPS | jq .cer -r)

# deploy infrastructure
az deployment group create \
    --resource-group $RG_NAME \
    --name infra-deployment \
    --template-file ./main.bicep \
    --parameters @main.parameters.json \
    --parameters location=$LOCATION \
    --parameters sshPublicKey="$SSH_KEY" \
    --parameters adminGroupObjectID=$ADMIN_GROUP_OBJECT_ID \
    --parameters k8sVersion=$LATEST_K8S_VERSION \
    --parameters dnsPrefix=$PREFIX \
    --parameters nginxBackendIpAddress=$INGRESS_PRIVATE_IP \
    --parameters nginxTlsCertSecretId=$CERT_SID \
    --parameters tlsCertSecretId=$PFX_CERT_SID \
    --parameters keyVaultName=$KV_NAME \
    --parameters internalHostName=$INTERNAL_HOST_NAME \
    --parameters publicDnsZoneResourceGroup=$PUBLIC_DNS_ZONE_RG_NAME

CLUSTER_NAME=$(az deployment group show --resource-group $RG_NAME --name infra-deployment --query 'properties.outputs.aksClusterName.value' -o tsv)
az aks get-credentials -g $RG_NAME -n $CLUSTER_NAME --admin

###################
# install NGINX 
###################

# Add the ingress-nginx repository
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx

# Use Helm to deploy an NGINX ingress controller
nginx_ingress_namespace='ingress-nginx-osm'
nginx_ingress_service='ingress-nginx'
osm_namespace='kube-system'
osm_mesh_name='osm'

helm install $nginx_ingress_service ingress-nginx/ingress-nginx \
    --version 4.3.0 \
    --namespace $nginx_ingress_namespace \
    --create-namespace \
    --set controller.replicaCount=2 \
    --set controller.nodeSelector."kubernetes\.io/os"=linux \
    --set controller.admissionWebhooks.patch.nodeSelector."kubernetes\.io/os"=linux \
    --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz \
    --set defaultBackend.nodeSelector."kubernetes\.io/os"=linux \
    -f ./manifests/internal-ingress.yaml

nginx_ingress_host="$(kubectl -n "$nginx_ingress_namespace" get service ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')"
nginx_ingress_port="$(kubectl -n "$nginx_ingress_namespace" get service ingress-nginx-controller -o jsonpath='{.spec.ports[?(@.name=="http")].port}')"

osm namespace add "$nginx_ingress_namespace" --mesh-name $osm_mesh_name --disable-sidecar-injection

# Create a namespace
kubectl create ns httpbin

# Add the namespace to the mesh
osm namespace add httpbin

# Deploy the application
kubectl apply -f https://raw.githubusercontent.com/openservicemesh/osm-docs/release-v1.2/manifests/samples/httpbin/httpbin.yaml -n httpbin

kubectl edit meshconfig osm-mesh-config -n $osm_namespace

# patch osm config with the settings below
:' 
certificate:
  ingressGateway:
    secret:
      name: osm-nginx-client-cert
      namespace: <osm-namespace> # replace <osm-namespace> with the namespace where OSM is installed
    subjectAltNames:
    - ingress-nginx.ingress-nginx.cluster.local
    validityDuration: 24h
'

# apply ingress
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: httpbin
  namespace: httpbin
  annotations:
    nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
    # proxy_ssl_name for a service is of the form <service-account>.<namespace>.cluster.local
    nginx.ingress.kubernetes.io/configuration-snippet: |
      proxy_ssl_name "httpbin.httpbin.cluster.local";
    nginx.ingress.kubernetes.io/proxy-ssl-secret: "kube-system/osm-nginx-client-cert"
    nginx.ingress.kubernetes.io/proxy-ssl-verify: "on"
spec:
  tls:
  - hosts:
    - internal.nginx.kainiindustries.net
    secretName: internal-nginx-kainiindustries-net
  ingressClassName: nginx
  rules:
  - host: internal.nginx.kainiindustries.net
    http:
      paths:
        - path: /
          pathType: Prefix
          backend:
            service:
              name: httpbin
              port:
                number: 14001
---
apiVersion: policy.openservicemesh.io/v1alpha1
kind: IngressBackend
metadata:
  name: httpbin
  namespace: httpbin
spec:
  backends:
  - name: httpbin
    port:
      number: 14001 # targetPort of httpbin service
      protocol: https
    tls:
      skipClientCertValidation: false
  sources:
  - kind: Service
    name: "$nginx_ingress_service-controller"
    namespace: "$nginx_ingress_namespace"
  - kind: AuthenticatedPrincipal
    name: ingress-nginx.ingress-nginx-osm.cluster.local
EOF

# create k8s secret for tls cert
kubectl create secret tls ${PRIVATE_CERT_NAME} --key ${PRIVATE_KEY_FILE} --cert ${PRIVATE_CERT_FILE} -n httpbin

# dump TLS cert & private key
kubectl get secret internal-nginx-kainiindustries-net -n httpbin -o jsonpath="{.data.tls\.crt}" | base64 -d
kubectl get secret internal-nginx-kainiindustries-net -n httpbin -o jsonpath="{.data.tls\.key}" | base64 -d
