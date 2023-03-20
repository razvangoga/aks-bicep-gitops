@description('The name of the Managed Cluster resource.')
param clusterName string

@description('The location of the Managed Cluster resource.')
param location string = resourceGroup().location

param provisionAks bool = true
param provisionArgo bool = true
param provisionFlux bool = true

param rbacRolesNeeded array = [
  'b24988ac-6180-42a0-ab88-20f7382dd24c' //Contributor
  '7f6c6a51-bcf8-42ba-9220-52d62157d7db' //Azure Kubernetes Service RBAC Reader
]

module aks 'aks.bicep' = if (provisionAks) {
  name: 'aks'
  params: {
    clusterName: clusterName
    location: location
  }
}

resource aksResource 'Microsoft.ContainerService/managedClusters@2022-11-02-preview' existing = {
  name: clusterName
}

resource aksrunidentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: 'aks-helm-install'
  location: location
  dependsOn: [
    aks
    aksResource
  ]
}

resource rbac 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for roleDefId in rbacRolesNeeded: {
  name: guid(aksResource.id, roleDefId, aksrunidentity.id)
  scope: aksResource
  dependsOn: [
    aks
    aksResource
  ]  
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefId)
    principalId: aksrunidentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}]

//pass is argonautsgo encrypted with bcrypt
// https://bcrypt-generator.com/
var pass = '$2a$10$PGzh9.vwZb765z5kV4Bp9eIKKvjsPYiQQkewrVaZuPeVTaQ56dR/y'

var argocdValues = loadTextContent('argocd.yaml')
var argocdAppValues = loadTextContent('argocd-apps.yaml')

module argocd 'helm.bicep' = if (provisionArgo) {
  name: 'argocd'
  dependsOn: [
    aks
    aksResource
  ]  
  params: {
    useExistingManagedIdentity: true
    managedIdentityName: aksrunidentity.name
    aksName: clusterName
    location: location
    helmApps: [
      {
        helmRepo: 'argo'
        helmRepoURL: 'https://argoproj.github.io/argo-helm'
        helmApp: 'argo/argo-cd'
        helmAppName: 'argocd'
        helmAppParams: '--namespace argocd --create-namespace --wait'
        //https://github.com/argoproj/argo-helm/blob/main/charts/argo-cd/values.yaml
        helmAppValues: argocdValues
        helmAppValueOverrides: '--set \'configs.secret.argocdServerAdminPassword=${pass}\''
      }, {
        helmRepo: 'argo'
        helmRepoURL: 'https://argoproj.github.io/argo-helm'
        helmApp: 'argo/argocd-apps'
        helmAppName: 'argocd-apps'
        helmAppParams: '--namespace argocd --create-namespace --wait'
        //https://github.com/argoproj/argo-helm/blob/main/charts/argocd-apps/values.yaml
        helmAppValues: argocdAppValues
      }
    ]
  }
}

var fluxcdSyncValues = loadTextContent('fluxcd-sync.yaml')
var fluxcdWeaveValues = loadTextContent('fluxcd-weave.yaml')

module fluxcd 'helm.bicep' = if (provisionFlux) {
  name: 'fluxcd'
  dependsOn: [
    aks
    aksResource
  ]  
  params: {
    useExistingManagedIdentity: true
    managedIdentityName: aksrunidentity.name
    aksName: clusterName
    location: location
    helmApps: [
      {
        helmRepo: 'fluxcd-community'
        helmRepoURL: 'https://fluxcd-community.github.io/helm-charts'
        helmApp: 'fluxcd-community/flux2'
        helmAppName: 'fluxcd'
        helmAppParams: '--namespace fluxcd --create-namespace --wait'
      }, {
        helmRepo: 'fluxcd-community'
        helmRepoURL: 'https://fluxcd-community.github.io/helm-charts'
        helmApp: 'fluxcd-community/flux2-sync'
        helmAppName: 'fluxcd-sync'
        helmAppParams: '--namespace fluxcd --create-namespace --wait'
        helmAppValues: fluxcdSyncValues
      }, {
        helmRepo: 'weave-gitops'
        helmRepoURL: 'https://helm.gitops.weave.works/'
        helmApp: 'weave-gitops/weave-gitops'
        helmAppName: 'fluxcd-ui'
        helmAppParams: '--namespace fluxcd --create-namespace --wait'
        helmAppValues: fluxcdWeaveValues
        helmAppValueOverrides: '--set \'adminUser.passwordHash=${pass}\''
      }
    ]
  }
}
