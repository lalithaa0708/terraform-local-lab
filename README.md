# Local Infrastructure-as-Code Lab

I wanted to learn Terraform properly, but my AWS account got stuck in
verification and I didn't want to wait. So I built the same three-tier
architecture locally instead — Docker for the first half, a real Kubernetes
cluster for the second. Turns out almost none of the important parts are
cloud-specific.

## Why I built it this way

The problem Terraform exists to solve is that infrastructure built by clicking
through a console slowly drifts apart. Someone sets up dev in March, someone
else sets up prod in September, and six months later a deploy fails at 9pm
because one of them is running a different Postgres version. Nobody wrote
anything down, so finding the difference means comparing two browser tabs.

So the point of this repo is that dev and prod come from the same code. You
can see it here:

```bash
diff day3/environments/dev/main.tf day3/environments/prod/main.tf
```

Three lines differ — the name, the replica count, the port. Everything else
comes from shared modules, so the two environments physically can't drift.

## What's here

    day1/   One container. Just enough to learn plan/apply/destroy.
    day2/   Three tiers: public network, private network, Postgres, app layer.
    day3/   The same thing refactored into modules, with dev and prod.
    day4/   Kubernetes — namespace, secret, deployment, service, probes.

They're meant to be worked through in order. Each one is a standalone
Terraform project.

## Running it

You'll need Docker Desktop running, plus Terraform, kind and kubectl.

```bash
cd day2
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform apply
```

Then http://localhost:8080. `terraform destroy` when you're done.

For day4 you need a cluster first:

```bash
kind create cluster --name tf-cluster --config day4/kind-config.yaml
```

## The architecture

                    localhost:8080
                          |
                  [ frontend network ]
                          |
                   +-------------+
                   |  app tier   |   scaled by app_replicas
                   +-------------+
                          |
                  [ backend network ]   internal = true
                          |
                   +-------------+
                   |  postgres   |   persistent volume
                   +-------------+

The backend network is marked `internal`, which is the local equivalent of
putting a database in a private subnet. You can check it actually works:

```bash
docker exec dev-app-1 ping -c 2 dev-database   # replies
docker exec dev-database ping -c 2 1.1.1.1     # Network unreachable
```


**You can't run nginx as a non-root user on port 80.** Checkov flagged the
container for running as root, and the fix isn't just setting `runAsNonRoot`.
Ports below 1024 are privileged, so I had to switch to
`nginxinc/nginx-unprivileged`, which listens on 8080, and update the probes
and service target port to match.

**Two environments can't both own the same Docker image.** Running
`terraform destroy` on dev failed because prod's container was still using
`postgres:16-alpine`, and dev's state thought it owned that image. Same
problem you'd get with two state files both managing a shared VPC. Destroying
prod first fixed it, but the real answer is that shared resources shouldn't be
declared in both.

**Secrets in environment variables leak more than I realised.** Checkov
suggested mounting them as files instead. Env vars turn up in
`kubectl describe pod`, in crash dumps, and every child process inherits them.
A mounted file only exists for whatever opens it, and it updates when the
secret changes instead of needing a pod restart.

## Security

Checkov runs over all of it: 28 checks pass, 2 I've accepted on purpose.

Fixed:
- runs as UID 101, non-root, at both pod and container level
- all Linux capabilities dropped, privilege escalation off
- unprivileged nginx image (see above)
- secret mounted as a file rather than an env var

Accepted, with reasons:
- `CKV_K8S_22` read-only root filesystem — nginx writes to /tmp and its cache
  dir, so this needs emptyDir mounts I haven't added yet
- `CKV_K8S_43` image digest pinning — sensible for production, but digests
  change on every rebuild and this is a learning repo



