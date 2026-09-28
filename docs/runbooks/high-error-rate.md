# Runbook: High error rate

## What this means
More than 14% of requests are returning 5xx. At this rate the monthly
error budget is gone in about two days.

## First checks
    kubectl get pods -n demo
    kubectl logs -n demo -l app=demo-app --tail=50
    kubectl rollout history deployment/demo-app -n demo

## Most likely cause
A recent deploy. Check whether the rollout timestamp lines up with when
the alert started.

## Mitigation
    kubectl rollout undo deployment/demo-app -n demo

## If that doesn't fix it
Check the database pod and recent config changes. Escalate if error rate
stays above 5% ten minutes after rollback.
