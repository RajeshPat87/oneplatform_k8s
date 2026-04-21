# security-mesh

| Chart        | Upstream                                                            |
|--------------|---------------------------------------------------------------------|
| vault        | hashicorp/vault                                                     |
| gatekeeper   | open-policy-agent/gatekeeper                                        |
| istio-base   | istio-release.storage.googleapis.com/charts (base)                  |
| istiod       | istio-release.storage.googleapis.com/charts (istiod)                |
| cilium       | Installed via AKS `network_dataplane = "cilium"` (in Terraform)     |

See `policies/opa/` for Gatekeeper constraint templates + constraints.
