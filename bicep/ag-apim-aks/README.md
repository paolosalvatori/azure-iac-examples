# Application Gateway, API Management, AKS example

This repo deploys an E2E solution to two expose APIs and a Javascript SPA, running in Kubernetes, to the Internet via Application Gateway & API Management.

The solution provisions the following resources:

- 2 x Virtual Networks (Hub & Spoke) with vNet peering
- Application Gateway
- API Management with Internal vNet integration
    - 2 x Open API definitions for each backend microservice
- AKS cluster
- Azure Monitor Workspace
- NSGs for AppGateway & API Management subnets
- Azure Container Registry
- Private DNS zone
- Public DNS records
- 2 x containerized Golang APIs ('product-api' & 'order-api')
    - each generated from their own Open API definition files
- 1 x containerized React SPA front end application running in an NGINX container

# Pre-requisites

- Windows 10/11 OS machine
- [PowerShell](https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell?view=powershell-7.2)
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- [Azure PowerShell Module](https://docs.microsoft.com/en-us/powershell/azure/install-az-ps?view=azps-8.1.0)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)

# Deployment

- cd `./scripts`
- create `./scripts/env.json` file  
  - populate file with the object below (change values to suit your environment)
  ```
    {
        "password": "<password for certificate>",
        "aksAdminGroupObjectId": "<objectId of AAD group containing AKS admin users>"
    }
  ```

- ensure you have AAD RBAC role to create:
  - application registrations
  - enterprise applications (service principals)
- authenticate azcli & Azure Powershell
  - `az login -tenant <AAD Tenant Id GUID>`
  - `Connect-AzAccount -TenantId <AAD Tenant Id GUID>`
- Execute the script, passing the required parameters
  - `./deploy.ps1 -Location <Azure region name> -AADTenant <AAD Tenant name> -PublicDnsZone <public Dns zone name>`
    
    example:

     ``./deploy.ps1 -Location australiaeast -AADTenant 'mytenant.com' -PublicDnsZone 'mydomain.com'``