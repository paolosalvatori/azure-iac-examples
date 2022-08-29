az k8s-extension create \
    --name <extension-name> \
    --extension-type Microsoft.AzureML.Kubernetes \
    --config enableTraining=True enableInference=True inferenceRouterServiceType=LoadBalancer allowInsecureConnections=True inferenceLoadBalancerHA=False \
    --cluster-type managedClusters \
    --cluster-name <your-AKS-cluster-name> \
    --resource-group <your-RG-name> \
    --scope cluster

az ml online-endpoint create --name hello-world-endpoint -f ./hello-world-endpoint.yaml -g mlops-aks-rg -w mlops-aks

az ml online-deployment create --name hello-worl-deployment -f ./hello-world-deployment.yaml -g mlops-aks-rg -w mlops-aks