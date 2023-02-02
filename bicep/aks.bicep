@description('The name of the Managed Cluster resource.')
param clusterName string

@description('The location of the Managed Cluster resource.')
param location string = resourceGroup().location

resource aks 'Microsoft.ContainerService/managedClusters@2022-11-02-preview' = {
  name: clusterName
  location: location
  identity: {
    type:'SystemAssigned'
  }
  properties: {
    dnsPrefix: replace(clusterName, '-', '')
    agentPoolProfiles: [
      {
        name: 'agentpool'
        count: 1
        vmSize: 'standard_d2s_v3'
        osType: 'Linux'
        mode: 'System'
      }
    ]
  }
}
