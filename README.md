# aks-bicep-gitops
a sample project for provisioning a gitops-ready azure aks cluster

- [helm.bicep](./bicep/helm.bicep) is taken from [this repo](https://github.com/aristosvo/aks-maffe-maandag) based on [this conversation](https://github.com/Azure/bicep/issues/9088)

## [ArgoCD](https://argo-cd.readthedocs.io/en/stable/)

An ArgoCD instance can be **completly** provisioned via Helm charts (with project, git repo link and app of apps definition) by using 2 helm charts:

- [main ArgoCD instance + git repo definition](https://github.com/argoproj/argo-helm/tree/main/charts/argo-cd)
- [declarative project / application definition](https://github.com/argoproj/argo-helm/tree/main/charts/argocd-apps)

## [FluxCD](https://fluxcd.io/)

TBD
