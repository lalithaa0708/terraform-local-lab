## CI/CD pipeline

Three gates run on every push and pull request, and they block rather than warn:

- **Gitleaks** — refuses commits containing credentials
- **Checkov** — refuses insecure Terraform (two findings skipped, documented above)
- **Trivy** — refuses images with fixable CRITICAL or HIGH CVEs

Deployment creates a Kubernetes cluster inside the runner, deploys, and verifies
the rollout. If the new version fails readiness, the pipeline rolls back on its
own and fails the build. Production deploys wait for manual approval.

### Automatic rollback

`docs/rollback-evidence.txt` is the real log from a deliberately broken deploy:

    13:43:44  rollout starts
    13:45:14  times out - one replica never became ready
    13:45:14  rolled back
    13:45:14  rollback complete, 70ms later
              build fails with exit code 1

No downtime during any of it. `maxUnavailable: 0` keeps the old pods serving
until new ones pass readiness, so when the broken version never became ready,
traffic never reached it. `failureThreshold: 2` on the readiness probe detects
it in about six seconds.

Reproduce it: Actions -> CD -> Run workflow -> tick `break_health`.

### Testing the gates

I tested each gate instead of assuming it worked, and the first Gitleaks test
passed when it should have failed.

The scan ran and read the file - 67 bytes, exactly the line I planted - and
reported no leaks. Two reasons:

1. I used AWS's own documentation example key, which scanners allowlist so they
   don't fire on every tutorial repo.
2. Gitleaks fingerprints access key IDs (`AKIA` + 16 chars), not secret access
   keys. A 40-character secret looks like any other hash or token, so matching
   it would generate constant false positives.

Retesting was also informative:

| Test string | Detected | Why |
|---|---|---|
| `AKIAQYLPMN5HXR7TZW3K` | yes | Right pattern, entropy 4.12 |
| `AKIA2E0A8F3B244C9986` | no | Right pattern, entropy too low - hex-only |
| AWS doc example secret key | no | Not a fingerprinted pattern; allowlisted |

So the rule needs the shape *and* enough randomness. The practical lesson is
that a green Gitleaks check means "no secrets matching known signatures", not
"no secrets". Evidence in `docs/gitleaks-findings.txt` and
`docs/secret-gate-evidence.txt`.
