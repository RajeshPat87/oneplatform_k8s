# observability

Actual installs are managed by ArgoCD — see `argocd-apps/<env>/platform-observability.yaml`.

| Chart                 | Upstream                                                     |
|-----------------------|--------------------------------------------------------------|
| kube-prometheus-stack | prometheus-community/kube-prometheus-stack                   |
| fluentd               | fluent/fluentd                                               |
| kubecost              | kubecost/cost-analyzer                                       |

Values overrides per env live inside the corresponding ArgoCD Application manifest.
