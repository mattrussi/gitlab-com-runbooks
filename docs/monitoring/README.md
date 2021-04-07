<!-- MARKER: do not edit this section directly. Edit services/service-catalog.yml then run scripts/generate-docs -->

**Table of Contents**

[[_TOC_]]

#  Monitoring Service
* [Service Overview](https://dashboards.gitlab.net/d/monitoring-main/monitoring-overview)
* **Alerts**: https://alerts.gitlab.net/#/alerts?filter=%7Btype%3D%22monitoring%22%2C%20tier%3D%22inf%22%7D
* **Label**: gitlab-com/gl-infra/production~"Service:Prometheus"

## Logging

* [system](https://log.gprd.gitlab.net/goto/3a0b51d10d33c9558765e97640acb325)
* [monitoring](https://log.gprd.gitlab.net/goto/09f7c84d5f36e3df0d03382dc350cddf)

## Troubleshooting Pointers

* [../ci-runners/ci-abuse-handling.md](../ci-runners/ci-abuse-handling.md)
* [../elastic/elasticsearch-integration-in-gitlab.md](../elastic/elasticsearch-integration-in-gitlab.md)
* [../license/license-gitlab-com.md](../license/license-gitlab-com.md)
* [alertmanager-notification-failures.md](alertmanager-notification-failures.md)
* [alerts_gke.md](alerts_gke.md)
* [alerts_manual.md](alerts_manual.md)
* [prometheus-failed-compactions.md](prometheus-failed-compactions.md)
* [prometheus-pod-crashlooping.md](prometheus-pod-crashlooping.md)
* [sentry-is-down.md](sentry-is-down.md)
* [thanos-compact.md](thanos-compact.md)
* [upgrades.md](upgrades.md)
* [../patroni/check_wraparound.md](../patroni/check_wraparound.md)
* [../patroni/log_analysis.md](../patroni/log_analysis.md)
* [../patroni/pg_repack.md](../patroni/pg_repack.md)
* [../patroni/postgres-checkup.md](../patroni/postgres-checkup.md)
* [../patroni/postgresql-locking.md](../patroni/postgresql-locking.md)
* [../patroni/postgresql-query-load-evaluation.md](../patroni/postgresql-query-load-evaluation.md)
* [../pgbouncer/patroni-consul-postgres-pgbouncer-interactions.md](../pgbouncer/patroni-consul-postgres-pgbouncer-interactions.md)
* [../pgbouncer/pgbouncer-add-instance.md](../pgbouncer/pgbouncer-add-instance.md)
* [../pgbouncer/pgbouncer-connections.md](../pgbouncer/pgbouncer-connections.md)
* [../redis/redis.md](../redis/redis.md)
* [../sidekiq/sidekiq-survival-guide-for-sres.md](../sidekiq/sidekiq-survival-guide-for-sres.md)
* [../uncategorized/access-gcp-hosts.md](../uncategorized/access-gcp-hosts.md)
* [../uncategorized/job_completion.md](../uncategorized/job_completion.md)
* [../uncategorized/k8s-new-cluster.md](../uncategorized/k8s-new-cluster.md)
* [../uncategorized/k8s-operations.md](../uncategorized/k8s-operations.md)
* [../uncategorized/packagecloud-infrastructure.md](../uncategorized/packagecloud-infrastructure.md)
* [../uncategorized/subnet-allocations.md](../uncategorized/subnet-allocations.md)
* [../version/version-gitlab-com.md](../version/version-gitlab-com.md)
<!-- END_MARKER -->


## Summary

[Monitoring infrastructure overview](https://youtu.be/HYHQNEB4Rk8)

[Monitoring infrastructure troubleshooting](https://youtu.be/iiLClqUQjYw)

[Metrics catalog README](https://gitlab.com/gitlab-com/runbooks/-/blob/master/metrics-catalog/README.md)

[Apdex alert guide](./apdex-alerts-guide.md)

![Logical scheme](./img/gitlab-monitoring.png)

[draw.io source](../../graphs/gitlab-monitoring.xml) for later modifications.

[video: delivery: intro to monitoring at gitlab.com](https://www.youtube.com/watch?reload=9&v=fDeeYqCnuoM&list=PL05JrBw4t0KoPzC03-4yXuJEWdUo7VZfX&index=13&t=0s)

[epic about figuring out and documenting monitoring](https://gitlab.com/groups/gitlab-com/gl-infra/-/epics/75)

[video: General metrics and anomaly detection](https://www.youtube.com/watch?reload=9&v=Oq5PHtgEM1g&feature=youtu.be)


GitLab monitoring consist of the following parts:

1. 3 prometheus instances - 2 for HA, 1 for public monitoring. Each has role `prometheus-server` in chef, which specifies which metrics to collect.
1. 2 alertmanager instances - each of alertmanagers connected to corresponding prometheus instance and alert about availability of prometheus servers (each) and other other specified [alerting rules](https://dev.gitlab.org/cookbooks/runbooks/tree/master/alerts) (only on prometheus.gitlab.com). Effective roles in chef for alertmanagers are - `prometheus-alertmanager`, `prometheus-gitlab-com-monitoring`, `prometheus-2-gitlab-com-monitoring`.
1. 1 haproxy instance - this is used for providing metrics for grafana in the case when one of the prometheus instances is down. Role in chef - `prometheus-haproxy`. So keeping prometheus instances collecting (scraping) metrics permanently is main thing to take care of.
1. 2 grafana instances - 1 for internal usage, 1 for public monitoring. Public grafana instance provides all dashboards tagged `public` from Internal one. (*TO BE COMPLETED HERE*)

Grafana dashboards on dashboards.gitlab.net are managed in 3 ways:

1. By hand, editing directly using the Grafana UI
1. Uploaded from https://gitlab.com/gitlab-com/runbooks/tree/master/dashboards, either:
   1. json - literally exported from grafana by hand, and added to that repo
   1. jsonnet - JSON generated using jsonnet/grafonnet; see https://gitlab.com/gitlab-com/runbooks/blob/master/dashboards/README.md

Grafana dashboards can utilize metrics from a specific Prometheus cluster (e.g. prometheus-app, prometheus-db, ...), but it's preferred to
use the "Global" data source as it points to Thanos which aggregates metrics from all Prometheus instances and it has higher data retention
than any of the regular Prometheus instances.

All dashbaords are downloaded/saved automatically into https://gitlab.com/gitlab-org/grafana-dashboards, in the dashboards directory.
This happens from the gitlab-grafan:export_dashboards recipe, which runs some Ruby/chef code at every *chef run* on the *public* dashboards server, pulling from the pulling from the *private* dashboards server and then committing any changes to the git repository.  The repo is also mirror to https://ops.gitlab.net/gitlab-org/grafana-dashboards

Grafana dashboards on dashboards.gitlab.com are synced from dashboards.gitlab.net every 5 minutes by a script (/usr/local/sbin/sync_grafana_dashboards) run by cron every 5 minutes on the public grafana server (dashboards-com-01-inf-ops.c.gitlab-ops.internal).

## Architecture

## Performance

## Scalability

## Availability

## Durability

## Security/Compliance

## Monitoring/Alerting

Grafana dashboard for the monitoring service.

## Links to further Documentation

* [./alerts_manual.md](./alerts_manual.md)
* [./common-tasks.md](./common-tasks.md)
