
### Business Requirements Document (BRD): Project "OnePlatform" & Smart Calculator

#### 1. Executive Summary
The objective is to establish a unified, cloud-native Kubernetes platform ("OnePlatform") that provides exponential capabilities spanning infrastructure provisioning, container orchestration, observability, security, platform engineering, and MLOps. This platform will serve as the foundation for an AI-Enhanced Digital Calculator application, demonstrating the end-to-end lifecycle from code commit to intelligent model inference.

#### 2. Project Objectives
* **Platform Standardization:** Consolidate infrastructure, networking, security, and deployments using best-in-class open-source/CNCF tools.
* **GitOps & Automation:** Achieve 100% automated deployments and drift reconciliation using ArgoCD and Helm.
* **AI/ML Integration:** Provide natively routed, scalable LLM and ML inference endpoints for intelligent application features.

#### 3. Functional Requirements (The Calculator App)
* **Frontend (GUI):** A React.js or Vue.js Single Page Application (SPA) providing a standard calculator interface and a "Natural Language Math" input field.
* **Backend (Core Logic):** A Python (FastAPI) or Java (Spring Boot) microservice to handle standard mathematical operations.
* **AI Microservice:** A Python service interfacing with Ollama/KServe to parse and solve complex word problems (e.g., "If I have 5 apples and buy 3 more, what is the square root of the total?").

#### 4. Non-Functional Requirements & Platform Tooling Matrix
The platform must support the following capabilities, mapped directly to the requested stack:

| Capability Domain | Tooling Implemented | Requirement Addressed |
| :--- | :--- | :--- |
| **Orchestration & Packaging** | Kubernetes, Docker, Helm | Containerization, scheduling, and standard package management. |
| **Infrastructure & Platform** | Terraform, Crossplane | IaC for base cloud resources (Terraform) and K8s-native cloud resource provisioning (Crossplane). |
| **CI/CD & Deployment** | ArgoCD | GitOps-driven continuous delivery and configuration drift management. |
| **Networking & Mesh** | NGINX Ingress, Istio, Envoy, Cilium | External traffic routing (NGINX), L7 traffic management (Envoy/Istio), Service Mesh features, and eBPF network security (Cilium). |
| **Observability** | Prometheus, Grafana, Fluentd, Kubecost | Metrics collection, dashboard visualization, log aggregation, and real-time cloud cost monitoring. |
| **Security & Governance** | Vault, OPA | Centralized secrets management and Policy-as-Code for cluster governance. |
| **Scaling** | KEDA | Event-driven auto-scaling based on custom metrics (e.g., queue length, HTTP traffic). |
| **MLOps & AI** | Kubeflow, MLflow, KServe, Ollama, Inference Gateway | ML pipelines, experiment tracking, model serving, local LLM hosting, and intelligent LLM traffic routing. |

---

### Monorepo Structure (`oneplatform_k8s`)

To manage this in a single repository, a strict directory hierarchy is required to separate platform infrastructure, application code, and deployment manifests.

```text
oneplatform_k8s/
├── platform-infra/                # Base Infrastructure
│   ├── terraform/                 # VPCs, Managed K8s (EKS/AKS), Node Groups
│   └── crossplane/                # Compositions and XR definitions for developer self-service
├── platform-services/             # Helm charts for platform tools
│   ├── observability/             # prometheus, grafana, fluentd, kubecost
│   ├── security-mesh/             # vault, opa, cilium, istio
│   ├── mlops/                     # kubeflow, mlflow, kserve, ollama
│   └── ingress-gitops/            # nginx-ingress, argocd, keda
├── apps/                          # Application Source Code
│   ├── calculator-frontend/       # React/Node.js GUI
│   ├── calculator-backend/        # Java/Python core logic
│   └── calculator-ai-service/     # Python LLM wrapper
├── ml-pipelines/                  # Kubeflow/MLflow definitions
│   └── math-ocr-model/            # Training scripts for OCR/Math models
└── argocd-apps/                   # GitOps Manifests (The source of truth for ArgoCD)
    ├── dev/
    ├── staging/
    └── prod/
```

---

### CI/CD Pipelines & Required Checks


You will need a Continuous Integration (CI) pipeline (e.g., GitHub Actions, GitLab CI) and a Continuous Deployment (CD) pipeline driven by ArgoCD.

#### 1. Continuous Integration (CI) Pipeline
Triggered on a Pull Request or Merge to `main` in the `/apps/` directory.

* **Step 1: Code Checkout & Setup:** Pull code, set up Python/Java/Node environments.
* **Step 2: Static Analysis & Linting:** * Run `pylint` / `Checkstyle` / `ESLint`.
    * Run `tfsec` or `tflint` for Terraform code.
* **Step 3: Unit Testing:** Execute PyTest or JUnit with a minimum code coverage threshold (e.g., 80%).
* **Step 4: SAST (Static Application Security Testing):** Run SonarQube or Semgrep to catch vulnerabilities in the source code.
* **Step 5: Docker Build:** Build the container images for frontend, backend, and AI service.
* **Step 6: Image Vulnerability Scanning:** Use Trivy or Clair to scan the built Docker images for CVEs. Fail the pipeline on critical vulnerabilities.
* **Step 7: Push to Registry:** Push images to Docker Hub, ECR, or ACR.
* **Step 8: Update Manifests:** An automated script updates the image tag in the respective Helm `values.yaml` files within the `argocd-apps/` directory and commits the change.

#### 2. Continuous Deployment (CD) Pipeline (GitOps)
* **Step 1: ArgoCD Sync:** ArgoCD detects the new commit in the `argocd-apps/` directory.
* **Step 2: Policy Evaluation:** OPA (Open Policy Agent) gatekeeper verifies that the incoming deployment manifests comply with organizational policies (e.g., resources limits exist, images are from trusted registries, no root user).
* **Step 3: Deployment Strategy:** ArgoCD orchestrates a rollout. For standard microservices, a Rolling Update. If utilizing Istio/Envoy, Argo Rollouts can be used for Canary or Blue/Green deployments.
* **Step 4: Dynamic Scaling Hook:** KEDA registers the deployment and begins monitoring Prometheus metrics to scale the new pods based on incoming traffic.
* **Step 5: MLOps Sync (If applicable):** Model updates are synchronized via MLflow model registry, and KServe triggers a rollout of the new InferenceService.

### Next Steps for Implementation
Given the sheer weight of this stack, attempting to deploy this all at once will result in resource exhaustion and infinite troubleshooting loops. I recommend building this in phases:
1.  **Phase 1 (Core):** Terraform cluster -> ArgoCD -> NGINX Ingress -> App Deployment.
2.  **Phase 2 (Observability & Security):** Prometheus/Grafana -> Fluentd -> Vault -> OPA.
3.  **Phase 3 (Advanced Networking):** Cilium -> Istio -> KEDA.
4.  **Phase 4 (MLOps):** Kubeflow -> MLflow -> Ollama -> KServe.

---

## Implementation Reference (this repo)

### Scaffold status
- `apps/calculator-frontend/` — React 18 + Vite SPA, Vitest, nginx runtime image, proxies `/api/backend` and `/api/ai` inside the cluster.
- `apps/calculator-backend/` — FastAPI (Python 3.12) safe-AST arithmetic evaluator, Prometheus metrics at `/metrics`, `/healthz`, `/readyz`, pytest + coverage ≥ 80%.
- `apps/calculator-ai-service/` — FastAPI LLM wrapper that calls Ollama/KServe, extracts a safe expression, and delegates evaluation to `calculator-backend`. Unit tests mock the LLM with `respx`.
- `helm/*` — Helm charts per service with `Deployment`, `Service`, optional `Ingress`, `ServiceMonitor`, and **KEDA** `ScaledObject`.
- `platform-infra/terraform/` — Azure infra with **one resource group per capability stack** (see matrix below). Enables Cilium dataplane on AKS and wires ACR pull for the kubelet identity.
- `platform-infra/crossplane/` — `Provider`, XRD, and `Composition` stubs so platform teams can expose self-service storage buckets.
- `argocd-apps/{dev,staging,prod}/` — App-of-apps manifests for calculator services and for platform Helm charts (NGINX Ingress, KEDA, kube-prometheus-stack, Fluentd, Kubecost, Vault, Gatekeeper, Istio base + istiod, MLflow, Ollama, KServe).
- `policies/opa/` — Gatekeeper constraint templates + constraints for required resource limits and trusted-registry enforcement.
- `.github/workflows/` — CI per app (lint → unit → SAST → Docker build → Trivy → push → GitOps bump), Terraform validate/plan/apply, Helm lint + kubeconform, OPA conftest.
- `.github/actions/gitops-bump/` — composite action that invokes `scripts/gitops_bump.py` to update the image tag in the right `argocd-apps/<env>/<app>.yaml` and commits the change.
- `scripts/` — one-time setup helpers:
  - `install-tool.sh <tool> <version>` — pinned, checksum-verified install of terraform, helm, kubectl, gitleaks, hadolint, trivy, codeql.
  - `ensure-tf-backend.sh` — idempotently creates the Terraform state RG, Storage Account, and blob container with secure defaults.
  - `bootstrap.sh <env>` — fetches AKS kubeconfig, installs ArgoCD, registers the app-of-apps for the chosen environment.
  - `gitops_bump.py` — rewrites the image tag in an ArgoCD Application manifest.

### Per-stack Azure Resource Groups
Every capability domain from the BRD tooling matrix lands in its own Azure resource group via `platform-infra/terraform/locals.tf`:

| Capability Stack      | Azure Resource Group                     | Core Resources                               |
|-----------------------|------------------------------------------|----------------------------------------------|
| Networking            | `rg-oneplatform-<env>-networking`        | VNet + `snet-aks`, `snet-pe` subnets         |
| Orchestration (AKS)   | `rg-oneplatform-<env>-aks` (+ node RG)   | AKS cluster (Cilium dataplane), apps pool    |
| Container Registry    | `rg-oneplatform-<env>-acr`               | Premium ACR (private endpoints)              |
| Observability         | `rg-oneplatform-<env>-observability`     | Log Analytics Workspace                      |
| Security & Mesh       | `rg-oneplatform-<env>-security-mesh`     | Azure Key Vault (RBAC)                       |
| MLOps & AI            | `rg-oneplatform-<env>-mlops`             | Storage Account + `mlflow-artifacts` container|
| Scaling               | `rg-oneplatform-<env>-scaling`           | (placeholder for future KEDA-triggered infra)|
| Ingress + GitOps      | `rg-oneplatform-<env>-ingress-gitops`    | (placeholder; runtime lives in-cluster)      |

In-cluster platform workloads (Prometheus, Grafana, Fluentd, Kubecost, Vault, Gatekeeper, Istio, KEDA, Kubeflow, MLflow, Ollama, KServe) run inside AKS but are *owned* by these RGs for billing/tagging clarity.

### Getting started

```bash
# 1. Install pinned tooling once (verified by sha256)
./scripts/install-tool.sh terraform 1.9.6
./scripts/install-tool.sh helm      3.15.4
./scripts/install-tool.sh kubectl   1.30.5
./scripts/install-tool.sh trivy     0.55.2

# 2. Login + bootstrap the Terraform backend (RG + Storage + container)
az login
./scripts/ensure-tf-backend.sh

# 3. Provision platform infra
cp platform-infra/terraform/terraform.tfvars.example platform-infra/terraform/terraform.tfvars
terraform -chdir=platform-infra/terraform init
terraform -chdir=platform-infra/terraform apply

# 4. Bootstrap ArgoCD + app-of-apps for dev
./scripts/bootstrap.sh dev

# 5. Watch everything sync
kubectl -n argocd get applications
```

### CI/CD pipelines

| Workflow                              | Purpose                                                                 |
|---------------------------------------|-------------------------------------------------------------------------|
| `.github/workflows/ci-backend.yml`    | ruff/pylint + pytest ≥ 80% + Semgrep + Docker + Trivy + ACR push + GitOps bump |
| `.github/workflows/ci-frontend.yml`   | ESLint + Vitest + Semgrep + Docker + Trivy + ACR push + GitOps bump     |
| `.github/workflows/ci-ai-service.yml` | Same gated pipeline for the AI service                                  |
| `.github/workflows/terraform.yml`     | fmt/validate/tflint/tfsec → plan (PR) → apply (main), with backend bootstrap |
| `.github/workflows/helm-lint.yml`     | `helm lint` + `kubeconform` validation for all charts                   |
| `.github/workflows/opa-conftest.yml`  | Renders charts and runs `conftest` against `policies/opa/`              |

CD is pure GitOps: when the CI job bumps the image tag in `argocd-apps/<env>/<app>.yaml`, ArgoCD sees the new commit on `main`, re-syncs, Gatekeeper admits the manifest, KEDA picks up the `ScaledObject`, and the deployment rolls.

### Required repo secrets
- `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID` — OIDC federated credentials for `azure/login@v2`.
- `ACR_NAME`, `ACR_LOGIN_SERVER` — your ACR output from Terraform.
- `ARGOCD_AUTH_TOKEN` *(optional)* — only if you trigger out-of-band `argocd app sync` from CI.

See `.env.example` for the full local-dev variable set.

---

## Azure Pipelines (mirror of GitHub Actions)

Everything the GH Actions workflows do is mirrored 1:1 under `.azure-pipelines/`. Pick GH Actions *or* Azure Pipelines; don't run both on the same push or they'll race on the GitOps bump commit.

### Layout
```
.azure-pipelines/
├── ci-backend.yml              # python lint+test → SAST → build+scan+push ACR → GitOps bump
├── ci-frontend.yml             # node  lint+test → SAST → build+scan+push ACR → GitOps bump
├── ci-ai-service.yml           # python lint+test → SAST → build+scan+push ACR → GitOps bump
├── terraform.yml               # fmt/validate/tflint/tfsec → plan (PR) → apply (main)
├── helm-lint.yml               # helm lint + kubeconform
├── opa-conftest.yml            # render charts + conftest against policies/opa/
└── templates/
    ├── python-lint-test.yml
    ├── node-lint-test.yml
    ├── sast-semgrep.yml
    ├── docker-build-scan-push.yml
    └── gitops-bump.yml
```

### One-time Azure DevOps setup

1. Push/import this repo into an Azure Repos Git repo (e.g. `oneplatform_k8s`).
2. Run the setup script — creates service connections, variable groups, environment, and pipelines:

```bash
export ADO_ORG_URL=https://dev.azure.com/RajeshPatibandla1987
export ADO_PROJECT=oneplatform
export ADO_REPO_NAME=oneplatform_k8s
export AZURE_SUBSCRIPTION_ID=<subId>
export AZURE_SUBSCRIPTION_NAME="<exact sub display name>"
export AZURE_TENANT_ID=<tenantId>
export ACR_NAME=<acr name from terraform output>
export ACR_LOGIN_SERVER=<acr login server>

./scripts/azdo-setup.sh
```

3. In the ADO UI:
   - Project Settings → Service connections → **azure-oneplatform** → convert to **Workload Identity Federation** (passwordless).
   - Pipelines → first run of each will prompt to authorize the `oneplatform-common` and `oneplatform-tf-backend` variable groups — click Permit.
   - Project Settings → Repositories → `oneplatform_k8s` → Security → enable **"Contribute"** and **"Create branch"** for the *Build Service* account (needed by the `gitops-bump` template to push the image-tag commit back).
   - Environments → `platform-dev` → add approval gates if you want manual promotion for `terraform apply`.

### Service connections created
| Name                | Type                         | Used by                            |
|---------------------|------------------------------|------------------------------------|
| `azure-oneplatform` | Azure Resource Manager (WIF) | `terraform.yml` (AzureCLI@2 tasks) |
| `acr-oneplatform`   | Docker Registry (ACR)        | `docker-build-scan-push.yml`       |

### Variable groups created
| Group                    | Variables                                                                                          |
|--------------------------|----------------------------------------------------------------------------------------------------|
| `oneplatform-common`     | `ACR_NAME`, `ACR_LOGIN_SERVER`, `AZURE_SUBSCRIPTION_ID`                                            |
| `oneplatform-tf-backend` | `TF_BACKEND_RESOURCE_GROUP_NAME`, `TF_BACKEND_STORAGE_ACCOUNT_NAME`, `TF_BACKEND_CONTAINER_NAME`, `TF_BACKEND_LOCATION` |

### Pipelines created (`oneplatform-*`)
| Pipeline                   | Equivalent GH workflow                         |
|----------------------------|------------------------------------------------|
| `oneplatform-ci-backend`   | `.github/workflows/ci-backend.yml`             |
| `oneplatform-ci-frontend`  | `.github/workflows/ci-frontend.yml`            |
| `oneplatform-ci-ai-service`| `.github/workflows/ci-ai-service.yml`          |
| `oneplatform-terraform`    | `.github/workflows/terraform.yml`              |
| `oneplatform-helm-lint`    | `.github/workflows/helm-lint.yml`              |
| `oneplatform-opa-conftest` | `.github/workflows/opa-conftest.yml`           |

### GitOps flow (unchanged)
`Azure Pipelines CI → ACR push → gitops-bump commits to main → ArgoCD syncs AKS`. ArgoCD still watches the same `argocd-apps/<env>/` directory, so the CD side is identical — you're only swapping the CI engine.