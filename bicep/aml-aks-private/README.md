# Secure Azure Machine Learning Workspace Deployment

## Prerequisites
- [install azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-linux?pivots=apt)

## Deployment steps
- create /scripts/.env file with the following content on separate lines
  - `DS_VM_PASSWORD='<your vm password>'`
  - `ADMIN_USER_OBJECT_ID="<your admin user objectId GUID>"`
- cd to /scripts and execute the deployment script
  - `$ cd ./scripts`
  - `$ ./deploy.sh`