<!-- MARKER: do not edit this section directly. Edit services/service-catalog.yml then run scripts/generate-docs -->

**Table of Contents**

[[_TOC_]]

#  Sidekiq Service
* [Service Overview](https://dashboards.gitlab.net/d/sidekiq-main/sidekiq-overview)
* **Alerts**: https://alerts.gitlab.net/#/alerts?filter=%7Btype%3D%22sidekiq%22%2C%20tier%3D%22sv%22%7D
* **Label**: gitlab-com/gl-infra/production~"Service:Sidekiq"

## Logging

* [Sidekiq](https://log.gprd.gitlab.net/goto/d7e4791e63d2a2b192514ac821c9f14f)
* [Rails](https://log.gprd.gitlab.net/goto/86fbcd537588abef69339a352ef81d72)
* [Puma](https://log.gprd.gitlab.net/goto/a2601cff0b6f000339e05cdb9deab58b)
* [Unstructured](https://console.cloud.google.com/logs/viewer?project=gitlab-production&interval=PT1H&resource=gce_instance&advancedFilter=jsonPayload.hostname%3A%22sidekiq%22%0Alabels.tag%3D%22unstructured.production%22&customFacets=labels.%22compute.googleapis.com%2Fresource_name%22)
* [system](https://log.gprd.gitlab.net/goto/72d0f3fdfd8db18db9800cc04d8b6f55)

## Troubleshooting Pointers

* [../elastic/elasticsearch-integration-in-gitlab.md](../elastic/elasticsearch-integration-in-gitlab.md)
* [../gitaly/storage-rebalancing.md](../gitaly/storage-rebalancing.md)
* [../kube/k8s-cluster-upgrade.md](../kube/k8s-cluster-upgrade.md)
* [../kube/k8s-operations.md](../kube/k8s-operations.md)
* [../kube/kubernetes.md](../kube/kubernetes.md)
* [../monitoring/apdex-alerts-guide.md](../monitoring/apdex-alerts-guide.md)
* [../onboarding/gitlab.com_on_k8s.md](../onboarding/gitlab.com_on_k8s.md)
* [../onboarding/kibana-diagnosis.md](../onboarding/kibana-diagnosis.md)
* [../patroni/database_peak_analysis.md](../patroni/database_peak_analysis.md)
* [../patroni/geo-patroni-cluster.md](../patroni/geo-patroni-cluster.md)
* [../patroni/pg_collect_query_data.md](../patroni/pg_collect_query_data.md)
* [../patroni/postgresql-locking.md](../patroni/postgresql-locking.md)
* [../pgbouncer/patroni-consul-postgres-pgbouncer-interactions.md](../pgbouncer/patroni-consul-postgres-pgbouncer-interactions.md)
* [../pgbouncer/pgbouncer-add-instance.md](../pgbouncer/pgbouncer-add-instance.md)
* [../pgbouncer/pgbouncer-connections.md](../pgbouncer/pgbouncer-connections.md)
* [../pgbouncer/pgbouncer-remove-instance.md](../pgbouncer/pgbouncer-remove-instance.md)
* [../pgbouncer/pgbouncer-saturation.md](../pgbouncer/pgbouncer-saturation.md)
* [../pgbouncer/service-pgbouncer.md](../pgbouncer/service-pgbouncer.md)
* [../redis/redis-sidekiq-catchall-workloads-reduction.md](../redis/redis-sidekiq-catchall-workloads-reduction.md)
* [../redis/redis-survival-guide-for-sres.md](../redis/redis-survival-guide-for-sres.md)
* [../redis/redis.md](../redis/redis.md)
* [creating-a-shard.md](creating-a-shard.md)
* [disabling-a-queue.md](disabling-a-queue.md)
* [large-pull-mirror-queue.md](large-pull-mirror-queue.md)
* [large-sidekiq-queue.md](large-sidekiq-queue.md)
* [queue-migration.md](queue-migration.md)
* [sidekiq-inspection.md](sidekiq-inspection.md)
* [sidekiq-queue-not-being-processed.md](sidekiq-queue-not-being-processed.md)
* [sidekiq-survival-guide-for-sres.md](sidekiq-survival-guide-for-sres.md)
* [sidekiq_error_rate_high.md](sidekiq_error_rate_high.md)
* [sidekiq_stats_no_longer_showing.md](sidekiq_stats_no_longer_showing.md)
* [../uncategorized/debug-failed-chef-provisioning.md](../uncategorized/debug-failed-chef-provisioning.md)
* [../uncategorized/manage-workers.md](../uncategorized/manage-workers.md)
* [../uncategorized/ruby-profiling.md](../uncategorized/ruby-profiling.md)
* [../uncategorized/tracing-app-db-queries.md](../uncategorized/tracing-app-db-queries.md)
* [../uncategorized/tweeting-guidelines.md](../uncategorized/tweeting-guidelines.md)
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
