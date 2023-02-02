@description('The name of the Managed Cluster resource.')
param clusterName string

@description('The location of the Managed Cluster resource.')
param location string = resourceGroup().location

param provisionAks bool = false
param provisionArgo bool = false
param provisionArgoApps bool = true
param provisionFlux bool = false

module aks 'aks.bicep' = if(provisionAks) {
  name: 'aks'
  params: {
    clusterName: clusterName
    location: location
  }
}

var argocdValues = loadJsonContent('argocd.json')
module argocd 'helm.bicep' = if(provisionArgo) {
  name: 'argocd'
  params: {
    useExistingManagedIdentity: false
    aksName: clusterName
    location: location
    helmRepo: 'argo'
    helmRepoURL: 'https://argoproj.github.io/argo-helm'
    helmApps: [
      {
        helmApp: 'argo/argo-cd'
        helmAppName: 'argocd'
        helmAppParams: '--namespace argocd --create-namespace'
        //https://github.com/argoproj/argo-helm/blob/main/charts/argo-cd/values.yaml
        helmAppValues: '--set-json=\'configs.repositories=${string(argocdValues.argocd.configs.repositories)}\''
      }
    ]
  }
}

module argocdApps 'helm.bicep' = if(provisionArgoApps) {
  name: 'argocdApps'
  params: {
    useExistingManagedIdentity: false
    aksName: clusterName
    location: location
    helmRepo: 'argo'
    helmRepoURL: 'https://argoproj.github.io/argo-helm'
    helmApps: [
      {
        helmApp: 'argo/argocd-apps'
        helmAppName: 'argocd-apps'
        helmAppParams: '--namespace argocd --create-namespace'
        //https://github.com/argoproj/argo-helm/blob/main/charts/argocd-apps/values.yaml
        helmAppValues: '--set-json=\'projects=${string(argocdValues.argocdApps.projects)}\' --set-json=\'applications=${string(argocdValues.argocdApps.applications)}\''
      }
    ]
  }
}

module fluxcd 'helm.bicep' = if(provisionFlux) {
  name: 'fluxcd'
  params: {
    useExistingManagedIdentity: false
    aksName: clusterName
    location: location
    helmRepo: 'fluxcd-community'
    helmRepoURL: 'https://fluxcd-community.github.io/helm-charts'
    helmApps: [
      {
        helmApp: 'fluxcd-community/flux2'
        helmAppName: 'fluxcd'
        helmAppParams: '--namespace fluxcd --create-namespace'
      }
    ]
  }
}
