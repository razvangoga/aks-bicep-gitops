@description('The name of the Managed Cluster resource.')
param clusterName string

@description('The location of the Managed Cluster resource.')
param location string = resourceGroup().location

module aks 'aks.bicep' = {
  name: 'aks'
  params: {
    clusterName: clusterName
    location: location
  }
}

module argocd 'helm.bicep' = {
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
        helmAppName: 'argo-cd'
        helmAppParams: '--namespace argo-cd --create-namespace'
      }
    ]
  }
}

module fluxcd 'helm.bicep' = {
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
        helmAppName: 'flux-cd'
        helmAppParams: '--namespace flux-cd --create-namespace'
      }
    ]
  }
}
