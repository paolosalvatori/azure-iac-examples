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

