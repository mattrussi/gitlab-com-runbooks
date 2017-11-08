# Gitaly is down

## First and foremost

*Don't Panic*

## Symptoms
* Message in prometheus-alerts _Blackbox git [pulls|pushes] over [https|ssh] are taking too long._

## Check dashboards

* Check the [timings dashboard](https://performance.gitlab.net/dashboard/db/gitlab-com-git-timings) to
see if the problem is specific to particular nfs shard or is the same across all storage nodes.
* Check the [host dashboard](https://performance.gitlab.net/dashboard/db/host-stats) if there appears to
be problems on a specific storage node.

## Verify the blackbox exporter is working properly

* https://gitlab.com/gl-infra/prometheus-git-exporter
