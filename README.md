# Local Infrastructure-as-Code Lab

A complete multi-tier environment provisioned with Terraform — no cloud account required.
Everything runs on your own machine using Docker and a local Kubernetes cluster (kind).

## The problem this solves

Infrastructure created by clicking through consoles drifts between environments.
Code works in dev and breaks in prod, nobody knows what exists, and creating a new
environment takes days. This project defines the entire environment as code, so
dev and prod are generated from identical modules and can be created or destroyed
with a single command.

## What's inside

```
day1/          Your first Terraform resource (one container)
day2/          Full three-tier stack: isolated networks, database, app tier
day3/          The same stack refactored into reusable modules + dev/prod
day4/          Kubernetes: namespace, secret, deployment, service, health probes
```

Work through them in order. Each folder is a standalone Terraform project.

## Prerequisites

```bash
brew install --cask docker      # then open Docker Desktop once
brew install terraform kind kubectl helm
```

Verify:

```bash
docker ps          # should print a table, not an error
terraform version  # should print v1.x
```

## How to run any day

```bash
cd day2
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
terraform apply
```

Tear down when finished:

```bash
terraform destroy
```

## Architecture (day2 / day3)

```
                    localhost:8080
                          |
                  [ frontend network ]
                          |
                   +-------------+
                   |  app tier   |   (scaled with app_replicas)
                   +-------------+
                          |
                  [ backend network ]      internal = true
                          |                no route to the internet
                   +-------------+
                   |  postgres   |         persistent volume
                   +-------------+
```

The backend network is marked `internal`, so the database is genuinely unreachable
from outside — the same isolation a private subnet provides in a cloud VPC.

## Results to measure and record

- Time a full `terraform apply` and note it in your README
- Run `checkov -d .` before and after fixing findings; record both counts
- Screenshot `docker ps` with dev and prod running simultaneously
- Screenshot the app recovering after `kubectl delete pod -n dev --all`
## Results

- **Provisioning time:** full environment from zero in under 2 minutes, versus hours of manual setup
- **No environment drift:** dev and prod generated from identical modules; only replica count and port differ
- **Network isolation verified:** the database container has no route to the internet — `ping` from inside returns "Network unreachable", not a timeout, meaning no route exists rather than traffic being blocked
- **Self-healing demonstrated:** deleting all pods leaves the service available throughout, because readiness probes withhold traffic until replacements are serving
- **Drift detection:** scaling the deployment manually with `kubectl` causes `terraform plan` to report the difference; `apply` reconciles it

## Security

Checkov runs against all Terraform: **28 checks pass, 2 accepted with rationale.**

Fixed during development:
- Non-root execution (`runAsNonRoot`, UID 101) at both pod and container level
- All Linux capabilities dropped; privilege escalation disabled
- Switched to `nginx-unprivileged` — standard nginx requires root to bind port 80
- Secrets mounted as files rather than environment variables, since env vars appear in `kubectl describe`, crash dumps, and inherited child processes

Accepted:
- `CKV_K8S_22` (read-only root filesystem) — nginx requires writable `/tmp` and cache paths; would need emptyDir mounts
- `CKV_K8S_43` (image digest pinning) — tags used for maintainability in a demo; production would pin digests with automated updates

