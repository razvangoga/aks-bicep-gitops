Clear-Host

$resourceGroupName='aks-gitops'
$location = 'westeurope'
$clusterName= 'aks-gitops'

az group create --name $resourceGroupName --location $location
az deployment group create --resource-group $resourceGroupName --template-file main.bicep --parameters clusterName=$clusterName

az aks get-credentials --resource-group $resourceGroupName --name $clusterName --overwrite-existing

$argoPasswordBase64 = $(kubectl get secret argocd-initial-admin-secret --namespace=argocd --template='{{.data.password}}')
$argoPassword = [System.Text.Encoding]::ASCII.GetString([System.Convert]::FromBase64String($argoPasswordBase64))

Write-Host "ArgoCD portal credeantials : admin / $argoPassword"
