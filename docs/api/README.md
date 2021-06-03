<!-- MARKER: do not edit this section directly. Edit services/service-catalog.yml then run scripts/generate-docs -->

**Table of Contents**

[[_TOC_]]

#  Api Service
* [Service Overview](https://dashboards.gitlab.net/d/api-main/api-overview)
* **Alerts**: https://alerts.gitlab.net/#/alerts?filter=%7Btype%3D%22api%22%2C%20tier%3D%22sv%22%7D
* **Label**: gitlab-com/gl-infra/production~"Service:API"

## Logging

* [Rails](https://log.gprd.gitlab.net/goto/f61f543b668c26f2dcdb8a0eb06e2edb)
* [Workhorse](https://log.gprd.gitlab.net/goto/66979d90ca195652b7a4d10d22ca2db7)
* [Kubernetes](https://log.gprd.gitlab.net/goto/88eab835042a07b213b8c7f24213d5bf)

## Troubleshooting Pointers

* [../ci-runners/ci-apdex-violating-slo.md](../ci-runners/ci-apdex-violating-slo.md)
* [../ci-runners/ci-runner-timeouts.md](../ci-runners/ci-runner-timeouts.md)
* [../ci-runners/ci_constantnumberoflongrunningrepeatedjobs.md](../ci-runners/ci_constantnumberoflongrunningrepeatedjobs.md)
* [../ci-runners/ci_graphs.md](../ci-runners/ci_graphs.md)
* [../ci-runners/ci_pending_builds.md](../ci-runners/ci_pending_builds.md)
* [../ci-runners/ci_runner_manager_errors.md](../ci-runners/ci_runner_manager_errors.md)
* [../cloudflare/logging.md](../cloudflare/logging.md)
* [../cloudflare/managing-traffic.md](../cloudflare/managing-traffic.md)
* [../cloudflare/services-locations.md](../cloudflare/services-locations.md)
* [../cloudflare/terraform.md](../cloudflare/terraform.md)
* [../config_management/chef-workflow.md](../config_management/chef-workflow.md)
* [../customers/api-key-rotation.md](../customers/api-key-rotation.md)
* [../elastic/elastic-cloud.md](../elastic/elastic-cloud.md)
* [../elastic/elasticsearch-integration-in-gitlab.md](../elastic/elasticsearch-integration-in-gitlab.md)
* [../frontend/block-things-in-haproxy.md](../frontend/block-things-in-haproxy.md)
* [../frontend/haproxy.md](../frontend/haproxy.md)
* [../frontend/ssh-maxstartups-breach.md](../frontend/ssh-maxstartups-breach.md)
* [../git/deploy-gitlab-rb-change.md](../git/deploy-gitlab-rb-change.md)
* [../git/purge-git-data.md](../git/purge-git-data.md)
* [../gitaly/git-high-cpu-and-memory-usage.md](../gitaly/git-high-cpu-and-memory-usage.md)
* [../gitaly/gitaly-token-rotation.md](../gitaly/gitaly-token-rotation.md)
* [../gitaly/storage-rebalancing.md](../gitaly/storage-rebalancing.md)
* [../gitaly/storage-servers.md](../gitaly/storage-servers.md)
* [../kas/kubernetes-agent-basic-troubleshooting.md](../kas/kubernetes-agent-basic-troubleshooting.md)
* [../kas/kubernetes-agent-disable-integrations.md](../kas/kubernetes-agent-disable-integrations.md)
* [../kube/k8s-oncall-setup.md](../kube/k8s-oncall-setup.md)
* [../monitoring/alertmanager-notification-failures.md](../monitoring/alertmanager-notification-failures.md)
* [../monitoring/alerts_manual.md](../monitoring/alerts_manual.md)
* [../monitoring/apdex-alerts-guide.md](../monitoring/apdex-alerts-guide.md)
* [../onboarding/architecture.md](../onboarding/architecture.md)
* [../onboarding/gitlab.com_on_k8s.md](../onboarding/gitlab.com_on_k8s.md)
* [../onboarding/kibana-diagnosis.md](../onboarding/kibana-diagnosis.md)
* [../patroni/geo-patroni-cluster.md](../patroni/geo-patroni-cluster.md)
* [../patroni/patroni-management.md](../patroni/patroni-management.md)
* [../patroni/pg_collect_query_data.md](../patroni/pg_collect_query_data.md)
* [../patroni/pg_repack.md](../patroni/pg_repack.md)
* [../patroni/postgres.md](../patroni/postgres.md)
* [../pgbouncer/patroni-consul-postgres-pgbouncer-interactions.md](../pgbouncer/patroni-consul-postgres-pgbouncer-interactions.md)
* [../pgbouncer/pgbouncer-connections.md](../pgbouncer/pgbouncer-connections.md)
* [../pgbouncer/pgbouncer-saturation.md](../pgbouncer/pgbouncer-saturation.md)
* [../redis/redis-survival-guide-for-sres.md](../redis/redis-survival-guide-for-sres.md)
* [../sidekiq/large-sidekiq-queue.md](../sidekiq/large-sidekiq-queue.md)
* [../sidekiq/sidekiq-survival-guide-for-sres.md](../sidekiq/sidekiq-survival-guide-for-sres.md)
* [../spamcheck/index.md](../spamcheck/index.md)
* [../uncategorized/blocked-user-logins.md](../uncategorized/blocked-user-logins.md)
* [../uncategorized/gemnasium_is_down.md](../uncategorized/gemnasium_is_down.md)
* [../uncategorized/manage-workers.md](../uncategorized/manage-workers.md)
* [../uncategorized/namespace-restore.md](../uncategorized/namespace-restore.md)
* [../uncategorized/pingdom.md](../uncategorized/pingdom.md)
* [../uncategorized/ruby-profiling.md](../uncategorized/ruby-profiling.md)
* [../uncategorized/shared-configurations.md](../uncategorized/shared-configurations.md)
* [../uncategorized/tracing-app-db-queries.md](../uncategorized/tracing-app-db-queries.md)
* [../web/static-repository-objects-caching.md](../web/static-repository-objects-caching.md)
<!-- END_MARKER -->


<!-- ## Summary -->

## Architecture

### Kubernetes Deployment

![Kubernetes Deployment Diagram](api_service_kubernetes_deployment.png)

<!-- ## Performance -->

<!-- ## Scalability -->

<!-- ## Availability -->

<!-- ## Durability -->

<!-- ## Security/Compliance -->

<!-- ## Monitoring/Alerting -->

<!-- ## Links to further Documentation -->
