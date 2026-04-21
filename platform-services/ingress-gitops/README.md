# ingress-gitops

| Chart          | Upstream                                |
|----------------|-----------------------------------------|
| ingress-nginx  | kubernetes/ingress-nginx                |
| argo-cd        | argoproj/argo-helm (installed bootstrap)|
| keda           | kedacore/charts                         |

ArgoCD itself is bootstrapped by `scripts/bootstrap.sh` (out-of-band), then the
`app-of-apps.yaml` takes over.
