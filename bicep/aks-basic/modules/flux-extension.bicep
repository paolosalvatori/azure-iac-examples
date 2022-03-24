param aksClusterName string
param gitRepoUrl string = 'https://github.com/cbellee/flux2-kustomize-helm-example'

resource aks 'Microsoft.ContainerService/managedClusters@2022-01-02-preview' existing = {
  name: aksClusterName
}

resource flux 'Microsoft.KubernetesConfiguration/extensions@2021-09-01' = {
  name: 'flux'
  scope: aks
  properties: {
    extensionType: 'microsoft.flux'
    scope: {
      cluster: {
        releaseNamespace: 'flux-system'
      }
    }
    autoUpgradeMinorVersion: true
  }
}

resource fluxConfig 'Microsoft.KubernetesConfiguration/fluxConfigurations@2021-11-01-preview' = {
  name: 'gitops-demo'
  scope: aks
  dependsOn: [
    flux
  ]
  properties: {
    scope: 'cluster'
    namespace: 'gitops-demo'
    sourceKind: 'GitRepository'
    suspend: false
    gitRepository: {
      url: gitRepoUrl
      timeoutInSeconds: 600
      syncIntervalInSeconds: 600
      repositoryRef: {
        branch: 'main'
      }

    }
    kustomizations: {
      infra: {
        path: './infrastructure'
        dependsOn: []
        timeoutInSeconds: 600
        syncIntervalInSeconds: 600
        validation: 'none'
        prune: true
      }
      apps: {
        path: './apps/staging'
        dependsOn: [
          {
            kustomizationName: 'infra'
          }
        ]
        timeoutInSeconds: 600
        syncIntervalInSeconds: 600
        retryIntervalInSeconds: 600
        prune: true
      }
    }
  }
}

