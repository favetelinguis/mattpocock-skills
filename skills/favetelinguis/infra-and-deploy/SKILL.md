---
name: infra-and-deploy
description: "Infrastructure and deployment reference for production-readiness-check's Production reviewer. Use when production-readiness-check calls it."
---

# Infrastructure and Deployment

In a repository with co-located infrastructure, **checking application code and unit tests is never enough**. Unit tests against mocks and static linters (`helm template`, `terraform validate`, `az bicep build`) only verify that templates and syntax render cleanly. They cannot verify IAM or RBAC permissions, live cluster or cloud state drift, secret existence, network and DNS routing, admission webhooks, or stateful resource replacement. **Only a live plan against target state and a deployment can verify an infrastructure boundary.**

## Verification tiers

Classify every touched seam into one of three tiers so no claim outruns what local checks prove:

| Tier                  | Seam                                                                                      | What local checks prove                          | What only a deploy proves                                    |
| --------------------- | ----------------------------------------------------------------------------------------- | ------------------------------------------------ | ------------------------------------------------------------ |
| **1. Application**    | Pure domain logic, UI, local DB queries                                                   | Behavior at the seam                             | Production load and vendor quirks                            |
| **2. Rendered Infra** | Helm, Kustomize, Dockerfile, Terraform, Bicep, CDK, CI YAML                               | Templates render, schemas validate, images build | Live state compatibility, permissions, quotas, secret values |
| **3. Live Boundary**  | AWS/Azure/GCP resources, K8s cluster, IAM/Workload Identity, DNS/TLS, stateful migrations | **Nothing**                                      | **Everything**                                               |

## Infrastructure inventory

The layers that govern runtime behavior, and where each one lives:

- **Packaging & runtime**: `Dockerfile`, `docker-compose*`, build scripts, entrypoint scripts.
- **Kubernetes & Helm**: `Chart.yaml`, `values*.yaml`, `templates/`, `kustomization.yaml`, raw manifests (`Deployment`, `StatefulSet`, `Service`, `Ingress`, `NetworkPolicy`, `ServiceAccount`, `ExternalSecret`, `SecretProviderClass`).
- **Cloud IaC**: Terraform/OpenTofu (`*.tf`, `*.tfvars`), Azure (`*.bicep`, `*.bicepparam`, ARM JSON), AWS (`cdk.json`, `template.yaml`, CloudFormation), Pulumi (`Pulumi*.yaml`).
- **Delivery pipelines**: `.github/workflows/`, `azure-pipelines.yml`, GitLab CI, ArgoCD/Flux GitOps manifests.

Every environment overlay (`dev`, `staging`, `prod`) counts as its own layer instance.

## The five-layer chain

A change to a runtime boundary ripples through all five layers:

```text
1. Application Code   (HTTP routes + API contract, env vars, secrets, ports, /healthz + /readyz, SIGTERM drain, SDK calls, DB/queue schemas)
        │
2. Container Image    (Dockerfile EXPOSE, build args, runtime packages, non-root user, entrypoint)
        │
3. Workload Manifest  (Helm values*.yaml + templates: env, secret refs, probes, resources, ServiceAccount, Ingress/Gateway routes, NetPol)
        │
4. Cloud IaC          (Terraform / Bicep / CDK: IAM Role / Azure Managed Identity, KeyVault / Secrets Manager, DB/Queue/Storage, VNet/VPC)
        │
5. CI/CD Pipeline     (lint/type/test gates, image build, plan/what-if stage, environment promotion, secret names, rollback job)
```

Parity checklist, every link in lockstep (a deliberately deferred link is a deployment blocker):

- **Config and secret parity**: a new or renamed environment variable or secret in application code is wired through `.env.example`, Dockerfile (if build-time), every environment's `values*.yaml` and K8s secret/configmap reference, Cloud IaC secret store outputs, and CI workflow `secrets.*` / `vars.*`.
- **Route and contract parity**: a new, renamed, or changed HTTP route (path, method, parameters, request or response shape, auth) is invisible to callers until every layer that publishes or admits it agrees. Whatever the language or framework, this covers: the API contract or spec (OpenAPI, AsyncAPI, GraphQL schema, protobuf) whether hand-written or generated from code, plus any committed generated artifact, client SDK, or contract test built from it; and every layer that routes traffic by path, such as Kubernetes `Ingress` or Gateway API `HTTPRoute`, service mesh routes, API gateways (AWS API Gateway, Azure API Management, Kong), load balancer rules, and CDN or WAF path allowlists, wherever they are defined (Helm, Terraform, Bicep, CDK, or vendor config). Per-route settings count too: auth policy, CORS, rate limits, timeouts, body size limits, and rewrites. A removed or changed route follows expand-contract so existing callers keep working through the rollout.
- **Identity and least-privilege parity**: a new cloud SDK call (S3, SQS, DynamoDB, Azure Blob, Service Bus, KeyVault, CosmosDB) mocked in unit tests has its exact action and resource scope in the IAM policy, OIDC trust, or Azure RBAC role assignment in IaC.
- **Lifecycle and probe parity**: application startup time, port, `/healthz` (liveness), `/readyz` (readiness), and `SIGTERM` shutdown duration match the container `EXPOSE`, K8s probe paths/timeouts, and `terminationGracePeriodSeconds`.

## Expand-contract

During a rollout, old and new pods run concurrently against the same database, queue, and config state. Old and new versions must coexist safely:

- **Database migrations and queue schemas**: ship in additive phases (**expand** -> **backfill** in throttled batches -> **contract** in a later deploy after no running code reads the old shape). Every migration has a tested rollback (`down`) path.
- **Environment variables, secrets, and config keys**: the new key lands alongside the old key; the old key goes only after the workload has rolled over.
- **Stateful cloud and cluster resources**: destructive replacement shows as `ForceNew` / `-/+` in Terraform, `Delete` or `Recreate` in Azure Bicep `what-if`, CloudFormation `Replacement: True`, or a change to an immutable Kubernetes field (`Service` selectors, `StatefulSet` `volumeClaimTemplates`). Each one is either refactored into an expand-contract sequence or flagged as a one-way door requiring human approval.

## Tier 2 static and dry-run checks

The highest-fidelity local verification, per stack, is in [references/stacks.md](references/stacks.md) (Helm/Kubernetes, Terraform/OpenTofu, Azure Bicep, AWS CDK/CloudFormation, Docker, CI/CD).

- Render and diff templates across **all** environment overlays, not just default values.
- Schema and policy validators where installed: `helm lint`, `helm template`, `kubeconform`, `terraform fmt -check && terraform validate`, `az bicep build && az bicep lint`, `cdk synth`, `actionlint`.
- Plan commands are non-mutating only (`terraform plan`, `az deployment group what-if`, `helm diff upgrade`, `kubectl diff`), and need read-only credentials. Applying to a shared environment needs explicit human confirmation.

## Unverified until deploy

A change touching Tier 2 or Tier 3 carries an explicit **Unverified Until Deploy** list:

1. **Verified locally (Tier 1 & 2)**: unit tests, rendered manifest diffs, static validation commands run.
2. **Unverifiable until deploy (Tier 3)**: the exact live boundaries (IAM/RBAC role bindings, secret existence in KeyVault/Secrets Manager, live cluster admission/upgrade, DNS/ingress routing, stateful migration execution).
3. **Live verification**:
   - **Pre-apply plan command**: the exact `terraform plan`, `az deployment group what-if`, `cdk diff`, or `helm diff upgrade` to inspect before applying.
   - **Post-deploy health check**: the probes and signals that confirm the deploy succeeded in the first 15 minutes.
   - **Rollback command**: the exact command to revert the release (`helm rollback`, workflow rollback dispatch, feature flag toggle, or migration `down`).
