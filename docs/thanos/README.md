<!-- MARKER: do not edit this section directly. Edit services/service-catalog.yml then run scripts/generate-docs -->

**Table of Contents**

[[_TOC_]]

# thanos Service

* [Service Overview](https://dashboards.gitlab.net/d/thanos-main/thanos-overview)
* **Alerts**: <https://alerts.gitlab.net/#/alerts?filter=%7Btype%3D%22thanos%22%2C%20tier%3D%22inf%22%7D>
* **Label**: gitlab-com/gl-infra/production~"Service::Thanos"

## Logging

* [system](https://log.gprd.gitlab.net/goto/3a0b51d10d33c9558765e97640acb325)
* [gstg](https://nonprod-log.gitlab.net/goto/73178d30-ab9a-11ed-9af2-6131f0ee4ce6)
* [ops](https://nonprod-log.gitlab.net/goto/c3052140-ab9a-11ed-9af2-6131f0ee4ce6)
* [pre](https://nonprod-log.gitlab.net/goto/f5420010-ab9a-11ed-9af2-6131f0ee4ce6)

## Troubleshooting Pointers

* [Deadtuples affecting query performance](../ci-runners/CiRunnersServiceQueuingQueriesDurationApdexSLOViolation.md)
* [How to detect CI Abuse](../ci-runners/ci-abuse-handling.md)
* [../ci-runners/ci-apdex-violating-slo.md](../ci-runners/ci-apdex-violating-slo.md)
* [Chef troubleshooting](../config_management/chef-troubleshooting.md)
* [ErrorTracking main troubleshooting document](../errortracking/overview.md)
* [Gitaly token rotation](../gitaly/gitaly-token-rotation.md)
* [`gitalyctl`](../gitaly/gitalyctl.md)
* [GitLab.com on Kubernetes](../kube/k8s-new-cluster.md)
* [How to resize Persistent Volumes in Kubernetes](../kube/k8s-pvc-resize.md)
* [StatefulSet Guidelines](../kube/sts-guidelines.md)
* [Mimir Onboarding](../mimir/getting-started.md)
* [Alertmanager Notification Failures](../monitoring/alertmanager-notification-failures.md)
* [Alerting](../monitoring/alerts_manual.md)
* [../monitoring/apdex-alerts-guide.md](../monitoring/apdex-alerts-guide.md)
* [../monitoring/prometheus-is-down.md](../monitoring/prometheus-is-down.md)
* [Prometheus pod crashlooping](../monitoring/prometheus-pod-crashlooping.md)
* [Thanos](../monitoring/thanos.md)
* [Upgrading Monitoring Components](../monitoring/upgrades.md)
* [Diagnosis with Kibana](../onboarding/kibana-diagnosis.md)
* [Block specific pages domains through HAproxy](../pages/block-pages-domain.md)
* [Recovering from CI Patroni cluster lagging too much or becoming completely broken](../patroni-ci/recovering_patroni_ci_intense_lagging_or_replication_stopped.md)
* [../patroni/database_peak_analysis.md](../patroni/database_peak_analysis.md)
* [Geo Patroni Cluster Management](../patroni/geo-patroni-cluster.md)
* [Mapping Postgres Statements, Slowlogs, Activity Monitoring and Traces](../patroni/mapping_statements.md)
* [../patroni/pg_collect_query_data.md](../patroni/pg_collect_query_data.md)
* [`pg_txid_xmin_age` Saturation Alert](../patroni/pg_xid_xmin_age_alert.md)
* [../patroni/postgres.md](../patroni/postgres.md)
* [../patroni/postgresql-backups-wale-walg.md](../patroni/postgresql-backups-wale-walg.md)
* [Rails SQL Apdex alerts](../patroni/rails-sql-apdex-slow.md)
* [Handling Unhealthy Patroni Replica](../patroni/unhealthy_patroni_node_handling.md)
* [Postgres Replicas](../postgres-dr-delayed/postgres-dr-replicas.md)
* [../redis/redis-functional-partitioning.md](../redis/redis-functional-partitioning.md)
* [A survival guide for SREs to working with Redis at GitLab](../redis/redis-survival-guide-for-sres.md)
* [../redis/redis.md](../redis/redis.md)
* [Container Registry Database Index Bloat](../registry/db-index-bloat.md)
* [Disabling Sidekiq workers](../sidekiq/disabling-a-worker.md)
* [[`SidekiqQueueTooLarge`](../../legacy-prometheus-rules/sidekiq-queues.yml)](../sidekiq/large-sidekiq-queue.md)
* [../sidekiq/sharding.md](../sidekiq/sharding.md)
* [GET Monitoring Setup](../staging-ref/get-monitoring-setup.md)
* [Vault Secrets Management](../vault/vault.md)
* [Diagnostic Reports](../web/diagnostic-reports.md)
* [Workhorse Image Scaler](../web/workhorse-image-scaler.md)
<!-- END_MARKER -->

<!-- ## Summary -->

<!-- ## Architecture -->

<!-- ## Performance -->

<!-- ## Scalability -->

<!-- ## Availability -->

<!-- ## Durability -->

<!-- ## Security/Compliance -->

<!-- ## Monitoring/Alerting -->

<!-- ## Links to further Documentation -->
