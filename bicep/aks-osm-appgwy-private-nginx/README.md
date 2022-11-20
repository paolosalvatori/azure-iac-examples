# Application Gateway, NGINX Ingress & OSM Service Mesh TLS/mTLS configuration

A demonstration of how to configure a secure ingress path from Azure Application Gateway to a pod running in AKS as part of an OSM service mesh.

## Prerequisites

- Bash shell (Linux, Windows Subsystem for Linux, MacOS, etc.)
- Azure subscription
- Install [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
- Install [Openssl](https://www.openssl.org/)
- A valid Public TLS certificate in .PFX format
- A local SSH public key (~/.ssh/id_rsa.pub)

## Install

- Place the public TLS certificate in new directory named 'certs'
- Create a local .env file with the following variables
  
    ```bash
      PFX_CERT_PASSWORD='your PFX certificate password' # password required to import PFX certificate into Azure Key Vault
      ADMIN_GROUP_OBJECT_ID='your AAD admin group ObjectId' # AAD group for AKS Cluster Admin role permissions (add your account to this group)
    ```

- Modify the script to point to the TLS certificate

    ```bash
      DOMAIN_NAME='your_public_domain_name'
      PUBLIC_PFX_CERT_FILE='./certs/your_public_domain_tls_pfx_certificate.pfx'
    ```

- Run the install script

    ```bash
      ./deploy.sh
    ```
