---
name: infra-and-deploy
description: "Trace, validate, and safely roll out changes in repositories with co-located infrastructure or deployment code. Use when a repo contains or modifies Helm charts, Kubernetes manifests, Kustomize, Terraform, OpenTofu, Azure Bicep or ARM, AWS CDK, CloudFormation, or SAM, Pulumi, Dockerfiles, database migrations, or CI/CD workflows, or when application code changes environment variables, secrets, ports, health probes, IAM or RBAC permissions, queues, or cloud resources."
---

# Infrastructure and Deployment

In a repository with co-located infrastructure, **checking application code and unit tests is never enough**. Unit tests against mocks and static linters (`helm template`, `terraform validate`, `az bicep build`) only verify that templates and syntax render cleanly. They cannot verify IAM or RBAC permissions, live cluster or cloud state drift, secret existence, network and DNS routing, admission webhooks, or stateful resource replacement. **Only a live plan against target state and a deployment can verify an infrastructure boundary.**

## Verification tiers

Classify every touched seam into one of three tiers so you never overclaim what local checks prove:

| Tier | Seam | What local checks prove | What only a deploy proves |
|---|---|---|---|
| **1. Application** | Pure domain logic, UI, local DB queries | Behavior at the seam | Production load and vendor quirks |
| **2. Rendered Infra** | Helm, Kustomize, Dockerfile, Terraform, Bicep, CDK, CI YAML | Templates render, schemas validate, images build | Live state compatibility, permissions, quotas, secret values |
| **3. Live Boundary** | AWS/Azure/GCP resources, K8s cluster, IAM/Workload Identity, DNS/TLS, stateful migrations | **Nothing** | **Everything** |

## Process

### 1. Inventory the co-located infrastructure

Scan the repository before making changes to locate every layer that governs runtime behavior:

- **Packaging & runtime**: `Dockerfile`, `docker-compose*`, build scripts, entrypoint scripts.
- **Kubernetes & Helm**: `Chart.yaml`, `values*.yaml`, `templates/`, `kustomization.yaml`, raw manifests (`Deployment`, `StatefulSet`, `Service`, `Ingress`, `NetworkPolicy`, `ServiceAccount`, `ExternalSecret`, `SecretProviderClass`).
- **Cloud IaC**: Terraform/OpenTofu (`*.tf`, `*.tfvars`), Azure (`*.bicep`, `*.bicepparam`, ARM JSON), AWS (`cdk.json`, `template.yaml`, CloudFormation), Pulumi (`Pulumi*.yaml`).
- **Delivery pipelines**: `.github/workflows/`, `azure-pipelines.yml`, GitLab CI, ArgoCD/Flux GitOps manifests.

**Done when:** every infrastructure file and environment overlay in the repo that relates to the task is identified.

### 2. Trace the full five-layer chain

Whenever you change application code that touches runtime boundaries, or change infrastructure code directly, trace the impact across all five layers:

```text
1. Application Code   (env vars, secrets, ports, /healthz + /readyz, SIGTERM drain, SDK calls, DB/queue schemas)
        │
2. Container Image    (Dockerfile EXPOSE, build args, runtime packages, non-root user, entrypoint)
        │
3. Workload Manifest  (Helm values*.yaml + templates: env, secret refs, probes, resources, ServiceAccount, Ingress/NetPol)
        │
4. Cloud IaC          (Terraform / Bicep / CDK: IAM Role / Azure Managed Identity, KeyVault / Secrets Manager, DB/Queue/Storage, VNet/VPC)
        │
5. CI/CD Pipeline     (lint/type/test gates, image build, plan/what-if stage, environment promotion, secret names, rollback job)
```

Check every link in the chain:

- **Config and secret parity**: a new or renamed environment variable or secret in application code must be wired through `.env.example`, Dockerfile (if build-time), every environment's `values*.yaml` and K8s secret/configmap reference, Cloud IaC secret store outputs, and CI workflow `secrets.*` / `vars.*`.
- **Identity and least-privilege parity**: a new cloud SDK call (S3, SQS, DynamoDB, Azure Blob, Service Bus, KeyVault, CosmosDB) mocked in unit tests must have its exact action and resource scope added to the IAM policy, OIDC trust, or Azure RBAC role assignment in IaC.
- **Lifecycle and probe parity**: application startup time, port, `/healthz` (liveness), `/readyz` (readiness), and `SIGTERM` shutdown duration must match the container `EXPOSE`, K8s probe paths/timeouts, and `terminationGracePeriodSeconds`.

**Done when:** every link in the chain from application code to CI/CD is updated in lockstep, or any intentionally deferred link is recorded as a deployment blocker.

### 3. Enforce expand-contract for stateful and rolling changes

During a deployment, old and new application pods run concurrently against the same database, queue, and config state.

- **Database migrations and queue schemas**: ship in additive phases (**expand** -> **backfill** in throttled batches -> **contract** in a later deploy after no running code reads the old shape). Every migration requires a tested rollback (`down`) path.
- **Environment variables, secrets, and config keys**: add the new key alongside the old key first; remove the old key only after the workload has rolled over.
- **Stateful cloud and cluster resources**: inspect IaC changes for destructive replacement (`ForceNew` / `-/+` in Terraform, `Delete` or `Recreate` in Azure Bicep `what-if`, CloudFormation `Replacement: True`, or immutable Kubernetes fields such as `Service` selectors and `StatefulSet` `volumeClaimTemplates`). Never silently ship an in-place change that destroys a stateful resource or fails `helm upgrade`.

**Done when:** old and new versions can coexist safely during rollout, and any destructive resource replacement is either refactored into an expand-contract sequence or flagged as a one-way door requiring human approval.

### 4. Run Tier 2 static and dry-run checks

Run the highest-fidelity verification available in the local environment before declaring implementation complete. Read [references/stacks.md](references/stacks.md) for the exact commands and checklists for Helm/Kubernetes, Terraform/OpenTofu, Azure Bicep, AWS CDK/CloudFormation, Docker, and CI/CD.

- Render and diff templates across **all** environment overlays (`dev`, `staging`, `prod`), not just default values.
- Run schema and policy validators where installed (`helm lint`, `helm template`, `kubeconform`, `terraform fmt -check && terraform validate`, `az bicep build && az bicep lint`, `cdk synth`, `actionlint`).
- When read-only cloud/cluster credentials are available and safe, run non-mutating plan commands (`terraform plan`, `az deployment group what-if`, `helm diff upgrade`, `kubectl diff`). Never apply mutations to shared environments without explicit user confirmation.

When provisioning credentials, CI secrets, or manual cloud dashboard steps are required that only a human can perform, call the Skill tool with "wizard" to generate an interactive setup script.

**Done when:** all local Tier 2 rendering, linting, and dry-run diffs pass across every environment overlay.

### 5. Emit the mandatory Deploy-Only Verification Warning

Whenever a change touches Tier 2 or Tier 3, include an explicit **Unverified Until Deploy** warning in your report and handoff (and feed it into `ship-pr` when opening a PR). State:

1. **What was verified locally (Tier 1 & 2)**: unit tests, rendered manifest diffs, static validation commands run.
2. **What cannot be verified until deploy (Tier 3)**: the exact live boundaries (IAM/RBAC role bindings, secret existence in KeyVault/Secrets Manager, live cluster admission/upgrade, DNS/ingress routing, stateful migration execution).
3. **Required live verification**:
   - **Pre-apply plan command**: the exact `terraform plan`, `az deployment group what-if`, `cdk diff`, or `helm diff upgrade` command to inspect before applying.
   - **Post-deploy observability checks**: call the Skill tool with "observability" to name the structured log events, RED/USE metrics, and health probes that confirm the deploy succeeded in the first 15 minutes.
   - **Rollback command**: the exact command to revert the release (`helm rollback`, workflow rollback dispatch, feature flag toggle, or migration `down`).

**Done when:** the user and PR have an explicit, copyable list of what local checks missed, how to verify the deploy live, and how to roll it back.
