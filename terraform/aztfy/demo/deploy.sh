# initialise Terraform
terraform init

# deploy 'dev' environment
terraform plan -var-file=./environments/dev.tfvars -out=./dev-plan
terraform apply -auto-approve ./dev-plan

# delete environment
terraform apply -destroy ./dev-plan

# deploy 'prod' environment
terraform plan -var-file=./environments/prod.tfvars -out=./prod-plan
terraform apply -auto-approve ./prod-plan

