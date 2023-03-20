rm values.yaml

pass=argonautsgo
passHash=$(htpasswd -nbBC 10 "" $pass  | tr -d ':\n' | sed 's/$2y/$2a/')

helm repo add argo https://argoproj.github.io/argo-helm && helm repo update && cat <<EOF | helm upgrade --install argocd argo/argo-cd --namespace argocd --create-namespace --set configs.secret.argocdServerAdminPassword=$passHash --values -
configs:
  repositories:
    aks-bicep-repo:
      name: aks-bicep-repo
      url: https://github.com/razvangoga/aks-bicep-gitops.git
EOF
