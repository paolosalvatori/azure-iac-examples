# Secure Azure Machine Learning Workspace Deployment

## Prerequisites
- [install azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-linux?pivots=apt)

## Deployment steps
- create .env file at the repo root with the following content on separate lines. The ADMIN_GROUP_OBJECT_ID is the ObjectId of a group containing user accounts who will be granted full RBAC access to the AKS cluster
  - `DS_VM_PASSWORD='<your vm password>'`
  - `ADMIN_GROUP_OBJECT_IDS="['<your group object id>']"`
- execute the deployment script
  - `$ ./deploy.sh`
