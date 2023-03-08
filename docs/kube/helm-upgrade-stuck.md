# Helm Upgrade is Stuck

On the `k8s-workloads/gitlab-com` repository, [we ask that helm be the
maintainer for
operations](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-com/-/blob/bc4d1c0b71668c679200ca282d5cd55a479837b2/bases/helmDefaults.yaml#L5).
This has a downside where if helm were to fail to talk to the Kubernetes API at
the right time, an upgrade will get stuck.

## Evidence

An auto-deploy will fail immediately with an error:

> `Error: UPGRADE FAILED: another operation (install/upgrade/rollback) is in
> progress`

## Information Gathering for Remediation

Ensure that no other pipelines are executing just in case we ran into an edge
case with resource locking and two CI jobs started executing against the same
cluster at the same time.  Remember that the jobs that run are located on our
ops instance.

Ensure that the last pipeline that failed contained sensible changes that are
safe to be rolled back.  This is highly dependent on the change itself and what
may go wrong if we rollback.  Example, if an Auto-Deploy failed, it's likely
that the rollout did complete, but Helm could not update it's state.  In
situations like this, rolling back is safe.  To reconcile the production
environment, we'd then need to retry the deployment job after remediation.  If,
for example, a configuration change was the result, validate that it is safe to
roll the config change back.

## Remediation

1. Log into the cluster
1. Rollback the stuck release: `helm rollback -n gitlab gitlab`
1. Validate that the next `helm status` indicates the deploy is complete
1. Continue remediation pending the situation that brought you here
