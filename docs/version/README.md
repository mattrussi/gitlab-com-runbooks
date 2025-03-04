<!-- MARKER: do not edit this section directly. Edit services/service-catalog.yml then run scripts/generate-docs -->

**Table of Contents**

[[_TOC_]]

# version.gitlab.com Service

* **Alerts**: <https://alerts.gitlab.net/#/alerts?filter=%7Btype%3D%22version%22%2C%20tier%3D%22sv%22%7D>
* **Label**: gitlab-com/gl-infra/production~"Service::Version"

## Logging

* [production.log](/var/log/version/)

## Troubleshooting Pointers

* [Upgrade camoproxy](../camoproxy/upgrade-camoproxy.md)
* [Cells and Auto-Deploy](../cells/auto-deploy.md)
* [Cells DNS](../cells/dns.md)
* [Infrastructure Development](../cells/infra-development.md)
* [../certificates/cloudflare.md](../certificates/cloudflare.md)
* [../certificates/gkms.md](../certificates/gkms.md)
* [../ci-runners/ci_pending_builds.md](../ci-runners/ci_pending_builds.md)
* [ClickHouse Cloud Failure Remediation, Backup & Restore Process](../clickhouse/backup-restore.md)
* [Cloudflare: Managing Traffic](../cloudflare/managing-traffic.md)
* [Service Locations](../cloudflare/services-locations.md)
* [Chef Guidelines](../config_management/chef-guidelines.md)
* [Chef Vault Basics](../config_management/chef-vault.md)
* [Chef Tips and Tools](../config_management/chef-workflow.md)
* [Chefspec](../config_management/chefspec.md)
* [design.gitlab.com Runbook](../design/design-gitlab-com.md)
* [../duo/code_suggestion_failover.md](../duo/code_suggestion_failover.md)
* [../duo/duo_license.md](../duo/duo_license.md)
* [../elastic/elastic-cloud.md](../elastic/elastic-cloud.md)
* [Gitaly error rate is too high](../gitaly/gitaly-error-rate.md)
* [Upgrading the OS of Gitaly VMs](../gitaly/gitaly-os-upgrade.md)
* [Gitaly version mismatch](../gitaly/gitaly-version-mismatch.md)
* [Managing GitLab Storage Shards (Gitaly)](../gitaly/storage-sharding.md)
* [../gitlab-com-pkgs/overview.md](../gitlab-com-pkgs/overview.md)
* [CI Artifacts CDN](../google-cloud-storage/artifacts-cdn.md)
* [Ad hoc observability tools on Kubernetes nodes](../kube/k8s-adhoc-observability.md)
* [Rebuilding a kubernetes cluster](../kube/k8s-cluster-rebuild.md)
* [GKE Cluster Upgrade Procedure](../kube/k8s-cluster-upgrade.md)
* [Isolating a pod](../kube/k8s-isolate-pod.md)
* [../kube/k8s-oncall-setup.md](../kube/k8s-oncall-setup.md)
* [../kube/k8s-operations.md](../kube/k8s-operations.md)
* [GKE/Kubernetes Administration](../kube/kube-administration.md)
* [Kubernetes](../kube/kubernetes.md)
* [../logging/logging_gcs_archive_bigquery.md](../logging/logging_gcs_archive_bigquery.md)
* [../monitoring/apdex-alerts-guide.md](../monitoring/apdex-alerts-guide.md)
* [../monitoring/filesystem_alerts_inodes.md](../monitoring/filesystem_alerts_inodes.md)
* [Session: Application architecture](../onboarding/architecture.md)
* [GPG Keys for Repository Metadata Signing](../packagecloud/manage-repository-metadata-signing-keys.md)
* [Re-indexing a package](../packagecloud/reindex-package.md)
* [GPG Keys for Package Signing](../packaging/manage-package-signing-keys.md)
* [Steps to create (or recreate) a Standby CLuster using a Snapshot from a Production cluster as Master cluster (instead of pg_basebackup)](../patroni/build_cluster_from_snapshot.md)
* [Custom PostgreSQL Package Build Process for Ubuntu Xenial 16.04](../patroni/custom_postgres_packages.md)
* [../patroni/database_peak_analysis.md](../patroni/database_peak_analysis.md)
* [Geo Patroni Cluster Management](../patroni/geo-patroni-cluster.md)
* [Patroni Cluster Management](../patroni/patroni-management.md)
* [Postgresql minor upgrade](../patroni/pg_minor_upgrade.md)
* [../patroni/postgres-checkup.md](../patroni/postgres-checkup.md)
* [postgres_exporter](../patroni/postgres_exporter.md)
* [../patroni/postgresql-backups-wale-walg.md](../patroni/postgresql-backups-wale-walg.md)
* [PostgreSQL VACUUM](../patroni/postgresql-vacuum.md)
* [SQL query analysis and optimization for Postgres](../patroni/query-analysis.md)
* [Postgres wait events analysis (a.k.a. Active Session History; ASH dashboard)](../patroni/wait-events-analisys.md)
* [../pgbouncer/patroni-consul-postgres-pgbouncer-interactions.md](../pgbouncer/patroni-consul-postgres-pgbouncer-interactions.md)
* [Postgres Replicas](../postgres-dr-delayed/postgres-dr-replicas.md)
* [../product_analytics/clickhouse-backup-restore.md](../product_analytics/clickhouse-backup-restore.md)
* [../product_analytics/k8s-architecture.md](../product_analytics/k8s-architecture.md)
* [Removing cache entries from Redis](../redis-cluster-cache/remove-cache-entries.md)
* [Provisioning Redis Cluster](../redis/provisioning-redis-cluster.md)
* [Redis-Sidekiq catchall workloads reduction](../redis/redis-sidekiq-catchall-workloads-reduction.md)
* [../redis/redis.md](../redis/redis.md)
* [Container Registry database post-deployment migrations](../registry/db-post-deployment-migrations.md)
* [High Number of Overdue Online GC Tasks](../registry/online-gc-high-overdue-tasks.md)
* [High build pressure](../release-management/build_pressure.md)
* [Managing Sentry in Kubernetes](../sentry/sentry.md)
* [Connecting To a Database via Teleport](../teleport/Connect_to_Database_Console_via_Teleport.md)
* [Teleport Administration](../teleport/teleport_admin.md)
* [Teleport Disaster Recovery](../teleport/teleport_disaster_recovery.md)
* [Aptly](../uncategorized/aptly.md)
* [Auto DevOps](../uncategorized/auto-devops.md)
* [Summary](../uncategorized/cloudsql-data-export.md)
* [GitLab dev environment](../uncategorized/dev-environment.md)
* [Managing Chef](../uncategorized/manage-chef.md)
* [Google mtail for prometheus metrics](../uncategorized/mtail.md)
* [Omnibus package troubleshooting](../uncategorized/omnibus-package-updates.md)
* [Project exports](../uncategorized/project-export.md)
* [Removing kernels from fleet](../uncategorized/remove-kernels.md)
* [How to Use Vault for Secrets Management in Infrastructure](../vault/usage.md)
* [Vault Secrets Management](../vault/vault.md)
* [version.gitlab.com Runbook](version-gitlab-com.md)
* [Static repository objects caching](../web/static-repository-objects-caching.md)
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
