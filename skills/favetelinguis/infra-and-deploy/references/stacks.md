# Stack Verification and Hardening Reference

Contents: Helm and Kubernetes, Terraform and OpenTofu, Azure (Bicep and ARM), AWS (CDK, CloudFormation, SAM), Docker and Containers, CI/CD Pipelines.

## Helm and Kubernetes

### Verification commands

```bash
# 1. Lint chart structure
helm lint <chart-dir>

# 2. Render templates for EVERY environment values file to catch nil-pointer or type bugs
for vf in <chart-dir>/values*.yaml; do
  echo "=== Rendering $vf ==="
  helm template test-release <chart-dir> -f "$vf" > "/tmp/rendered-$(basename "$vf")"
done

# 3. Validate against Kubernetes OpenAPI schemas (if kubeconform is installed)
kubeconform -strict -summary /tmp/rendered-*.yaml

# 4. Live cluster dry-run / diff (only when connected to target cluster context)
helm diff upgrade <release> <chart-dir> -f <values-file> --namespace <ns>
kubectl apply --dry-run=server -f /tmp/rendered-values.yaml
```

### Checklist and gotchas

- **Immutable fields**: changing `spec.selector` on a `Deployment`/`StatefulSet` or `volumeClaimTemplates` on a `StatefulSet` passes `helm template` locally but **fails** `helm upgrade` in the cluster.
- **Probes and graceful shutdown**: configure both `readinessProbe` (stops traffic when overloaded or shutting down) and `livenessProbe` (restarts deadlocked containers; never point liveness at external dependencies or a downstream outage will cascade-restart your fleet). Handle `SIGTERM` and set `terminationGracePeriodSeconds` longer than in-flight request drain time.
- **Resource requests/limits and securityContext**: set `requests` (CPU/memory), `runAsNonRoot: true`, `allowPrivilegeEscalation: false`, and `seccompProfile: RuntimeDefault`.
- **PodDisruptionBudget and topologySpreadConstraints**: required for multi-replica production workloads so node drains do not take down the service.
- **Secret mounting**: verify whether secrets come from `ExternalSecret`, CSI `SecretProviderClass` (Azure KeyVault / AWS Secrets Manager), or native K8s `Secret`, and confirm the key names match what the container reads.

## Terraform and OpenTofu

### Verification commands

```bash
terraform fmt -check -recursive
terraform init -backend=false
terraform validate

# When state access is available:
terraform plan -out=tfplan
terraform show -no-color tfplan
```

### Checklist and gotchas

- **Watch for `-/+` (destroy and recreate)**: check every `plan` output for forced replacement on stateful resources (databases, storage buckets, encryption keys, VPCs/VNets, load balancers with static DNS/IPs). Guard critical stateful resources with `lifecycle { prevent_destroy = true }`.
- **IAM / RBAC drift**: local `terraform validate` checks HCL syntax only; it does not check whether IAM policy JSON actions exist, whether ARNs/scopes match, or whether the deploying principal has permission to attach them.
- **State and module pinning**: pin provider and module versions; never hardcode environment names or account IDs that belong in variables.

## Azure (Bicep and ARM)

### Verification commands

```bash
# Compile and lint Bicep templates locally
az bicep build --file <main.bicep> --stdout > /tmp/compiled.json
az bicep lint --file <main.bicep>

# Live pre-deploy preview against target Resource Group (requires az login)
az deployment group what-if \
  --resource-group <rg-name> \
  --template-file <main.bicep> \
  --parameters <env.bicepparam>
```

### Checklist and gotchas

- **`what-if` noise vs real deletes**: inspect `Delete` and `Modify` entries in `az deployment group what-if`. Changing an Azure resource's `name`, `location`, `sku` (on some tiers), or subnet delegation triggers a destructive recreation or deployment failure.
- **Managed Identity and KeyVault / RBAC**: Bicep deploys the `Microsoft.Authorization/roleAssignments` resource, but Azure AD RBAC propagation can take several minutes after deploy before pods using Workload Identity can read KeyVault or Service Bus.
- **AKS + KeyVault CSI**: adding a secret to KeyVault requires updating both the Bicep KeyVault secret, the K8s `SecretProviderClass` `objects` array, and the Deployment `env`/`volumeMounts`.

## AWS (CDK, CloudFormation, SAM)

### Verification commands

```bash
# AWS CDK
npx cdk synth
npx cdk diff <StackName>

# CloudFormation / SAM
cfn-lint template.yaml
sam validate --lint
```

### Checklist and gotchas

- **CloudFormation replacement (`Replacement: True` / `Conditional`)**: check `cdk diff` or change sets for any resource marked `[~] ... (requires replacement)`. Replacing an RDS instance, DynamoDB table, Cognito UserPool, or SQS queue loses state or changes URLs/ARNs unless migrated via expand-contract.
- **IAM IRSA / Pod Identity**: confirm the K8s `ServiceAccount` name and namespace in the Helm chart exactly match the OIDC subject condition in the AWS IAM Role trust policy.

## Docker and Containers

- **Multi-stage builds**: keep build toolchains out of the runtime image.
- **Pin base images** (version tag + digest in production) and copy lockfiles before source code to preserve layer caching.
- **Run as non-root** (`USER node` / `USER 65532`) and ensure writable paths (`/tmp`, cache dirs) match K8s `readOnlyRootFilesystem` settings.
- **Signal forwarding**: use exec form `ENTRYPOINT ["node", "dist/server.js"]` (not shell form `sh -c`) so `PID 1` or `tini` forwards `SIGTERM` for graceful drain.

## CI/CD Pipelines

- **Shift-Left quality gate order**: `lint` -> `typecheck` -> `unit tests` -> `build + infra template render` -> `integration tests` -> `security audit` -> `staging deploy + smoke test` -> `production plan + deploy`.
- **Never interpolate untrusted inputs** (`${{ github.event.pull_request.title }}`, `${{ inputs.* }}`) directly inside `run: |` shell blocks; bind them to `env:` variables first to prevent shell injection.
- **Separate CI secrets from production secrets**: authenticate deployment jobs with short-lived OIDC federation (GitHub Actions OIDC -> AWS IAM Role / Azure Federated Credential) rather than long-lived static keys.
