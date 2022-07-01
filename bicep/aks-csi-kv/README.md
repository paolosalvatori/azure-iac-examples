# AKS CSI driver for Keyvault example with multiple User Managed Identites & Keyvaults

## Pre-requisites
- Bash shell
- [yq](https://github.com/mikefarah/yq/releases/tag/v4.25.3)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)

## Install
- Execute  `./deploy.sh` to create:
  - 1 AKS cluster
  - 2 Key Vaults
  - 2 User Managed Identities
- Execute `./setup.sh` to create:
  - 2 namespaces
  - Deploy the CSI driver addon
  - Generate & apply SecreProviderClass manifests
  - Generate & apply example pod manifests
