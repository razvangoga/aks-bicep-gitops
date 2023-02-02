Clear-Host

$resourceGroupName='aks-gitops'
$location = 'westeurope'
$clusterName= 'aks-gitops'

az group create --name $resourceGroupName --location $location
az deployment group create --resource-group $resourceGroupName --template-file main.bicep --parameters clusterName=$clusterName

az aks get-credentials --resource-group $resourceGroupName --name $clusterName --overwrite-existing
