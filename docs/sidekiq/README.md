<!-- MARKER: do not edit this section directly. Edit services/service-catalog.yml then run scripts/generate-docs -->

**Table of Contents**

[[_TOC_]]

# Sidekiq Service

* [Service Overview](https://dashboards.gitlab.net/d/sidekiq-main/sidekiq-overview)
* **Alerts**: <https://alerts.gitlab.net/#/alerts?filter=%7Btype%3D%22sidekiq%22%2C%20tier%3D%22sv%22%7D>
* **Label**: gitlab-com/gl-infra/production~"Service:Sidekiq"

## Logging

* [Sidekiq](https://log.gprd.gitlab.net/goto/d7e4791e63d2a2b192514ac821c9f14f)
* [Rails](https://log.gprd.gitlab.net/goto/86fbcd537588abef69339a352ef81d72)
* [Puma](https://log.gprd.gitlab.net/goto/a2601cff0b6f000339e05cdb9deab58b)
* [Unstructured](https://console.cloud.google.com/logs/viewer?project=gitlab-production&interval=PT1H&resource=gce_instance&advancedFilter=jsonPayload.hostname%3A%22sidekiq%22%0Alabels.tag%3D%22unstructured.production%22&customFacets=labels.%22compute.googleapis.com%2Fresource_name%22)
* [system](https://log.gprd.gitlab.net/goto/72d0f3fdfd8db18db9800cc04d8b6f55)

## Troubleshooting Pointers

* [CustomersDot main troubleshoot documentation](../customersdot/overview.md)
* [../elastic/elasticsearch-integration-in-gitlab.md](../elastic/elasticsearch-integration-in-gitlab.md)
* [GitLab Storage Re-balancing](../gitaly/storage-rebalancing.md)
* [GKE Cluster Upgrade Procedure](../kube/k8s-cluster-upgrade.md)
* [../kube/k8s-operations.md](../kube/k8s-operations.md)
* [Kubernetes](../kube/kubernetes.md)
* [../monitoring/apdex-alerts-guide.md](../monitoring/apdex-alerts-guide.md)
* [Gitlab.com on Kubernetes](../onboarding/gitlab.com_on_k8s.md)
* [Diagnosis with Kibana](../onboarding/kibana-diagnosis.md)
* [../patroni/database_peak_analysis.md](../patroni/database_peak_analysis.md)
* [Geo Patroni Cluster Management](../patroni/geo-patroni-cluster.md)
* [OS Upgrade Reference Architecture](../patroni/os_upgrade_reference_architecture.md)
* [../patroni/pg_collect_query_data.md](../patroni/pg_collect_query_data.md)
* [../patroni/postgresql-locking.md](../patroni/postgresql-locking.md)
* [How to provision the benchmark environment](../patroni/provisioning_bench_env.md)
* [../pgbouncer/patroni-consul-postgres-pgbouncer-interactions.md](../pgbouncer/patroni-consul-postgres-pgbouncer-interactions.md)
* [Add a new PgBouncer instance](../pgbouncer/pgbouncer-add-instance.md)
* [PgBouncer connection management and troubleshooting](../pgbouncer/pgbouncer-connections.md)
* [Removing a PgBouncer instance](../pgbouncer/pgbouncer-remove-instance.md)
* [Sidekiq or Web/API is using most of its PgBouncer connections](../pgbouncer/pgbouncer-saturation.md)
* [../pgbouncer/service-pgbouncer.md](../pgbouncer/service-pgbouncer.md)
* [Redis-Sidekiq catchall workloads reduction](../redis/redis-sidekiq-catchall-workloads-reduction.md)
* [A survival guide for SREs to working with Redis at GitLab](../redis/redis-survival-guide-for-sres.md)
* [../redis/redis.md](../redis/redis.md)
* [Container Registry Migration Phase 2](../registry/migration-phase2.md)
* [Creating a Sidekiq Shard](creating-a-shard.md)
* [Disabling a Sidekiq queue](disabling-a-queue.md)
* [Pull mirror overdue queue is too large](large-pull-mirror-queue.md)
* [Sidekiq Queue Out of Control](large-sidekiq-queue.md)
* [Sidekiq queue migration](queue-migration.md)
* [Poking around at sidekiq's running state](sidekiq-inspection.md)
* [Sidekiq queue no longer being processed](sidekiq-queue-not-being-processed.md)
* [A survival guide for SREs to working with Sidekiq at GitLab](sidekiq-survival-guide-for-sres.md)
* [sidekiq_error_rate_high.md](sidekiq_error_rate_high.md)
* [sidekiq_stats_no_longer_showing.md](sidekiq_stats_no_longer_showing.md)
* [Debug failed chef provisioning](../uncategorized/debug-failed-chef-provisioning.md)
* [Ruby profiling](../uncategorized/ruby-profiling.md)
* [GitLab staging environment](../uncategorized/staging-environment.md)
* [Application Database Queries](../uncategorized/tracing-app-db-queries.md)
* [Tweeting Guidelines](../uncategorized/tweeting-guidelines.md)
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
