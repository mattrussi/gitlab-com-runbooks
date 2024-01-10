<!-- MARKER: do not edit this section directly. Edit services/service-catalog.yml then run scripts/generate-docs -->

**Table of Contents**

[[_TOC_]]

# About Service

* **Alerts**: <https://alerts.gitlab.net/#/alerts?filter=%7Btype%3D%22about%22%2C%20tier%3D%22sv%22%7D>
* **Label**: gitlab-com/gl-infra/production~"Service::About"

## Logging

* [stackdriver](https://console.cloud.google.com/logs)

## Troubleshooting Pointers

* [../bastions/gprd-bastions.md](../bastions/gprd-bastions.md)
* [../bastions/gstg-bastions.md](../bastions/gstg-bastions.md)
* [../bastions/ops-bastions.md](../bastions/ops-bastions.md)
* [../certificates/chef_vault.md](../certificates/chef_vault.md)
* [How to detect CI Abuse](../ci-runners/ci-abuse-handling.md)
* [../ci-runners/ci_constantnumberoflongrunningrepeatedjobs.md](../ci-runners/ci_constantnumberoflongrunningrepeatedjobs.md)
* [../ci-runners/ci_graphs.md](../ci-runners/ci_graphs.md)
* [../ci-runners/service-ci-runners.md](../ci-runners/service-ci-runners.md)
* [Cloudflare Audit Log Rule Processing](../cloudflare/cloudflare-audit-log-rule-processing.md)
* [Cloudflare: Managing Traffic](../cloudflare/managing-traffic.md)
* [Service Locations](../cloudflare/services-locations.md)
* [Chef Guidelines](../config_management/chef-guidelines.md)
* [contributors.gitlab.com](../contributors/contributors-dashboard.md)
* [Backups](../customersdot/backups.md)
* [CustomersDot main troubleshoot documentation](../customersdot/overview.md)
* [CI Mirrored Tables](../decomposition/ci-mirrored-tables.md)
* [design.gitlab.com Runbook](../design/design-gitlab-com.md)
* [What is Programmable Search Engine?](../docs.gitlab.com/programmableSearch.md)
* [../elastic/elasticsearch-integration-in-gitlab.md](../elastic/elasticsearch-integration-in-gitlab.md)
* [ErrorTracking main troubleshooting document](../errortracking/overview.md)
* [Management for forum.gitlab.com](../forum/discourse-forum.md)
* [SSL Certificate Expiring or Expired](../frontend/ssl_cert.md)
* [Upgrading the OS of Gitaly VMs](../gitaly/gitaly-os-upgrade.md)
* [Gitaly repository cgroups](../gitaly/gitaly-repos-cgroup.md)
* [Restoring gitaly data corruption on a project after an unclean shutdown](../gitaly/gitaly-repository-corruption.md)
* [Gitaly multi-project migration](../gitaly/multi-project-migration.md)
* [GitLab Storage Re-balancing](../gitaly/storage-rebalancing.md)
* [GKE Cluster Upgrade Procedure](../kube/k8s-cluster-upgrade.md)
* [GitLab.com on Kubernetes](../kube/k8s-new-cluster.md)
* [../kube/k8s-oncall-setup.md](../kube/k8s-oncall-setup.md)
* [../kube/k8s-operations.md](../kube/k8s-operations.md)
* [StatefulSet Guidelines](../kube/sts-guidelines.md)
* [Traffic Cessation Alerts](../metrics-catalog/traffic-cessation-alerts.md)
* [Advisory Database Unresponsive Hosts/Outdated Repositories](../monitoring/advisory_db-unresponsive-hosts.md)
* [Alerting](../monitoring/alerts_manual.md)
* [../monitoring/apdex-alerts-guide.md](../monitoring/apdex-alerts-guide.md)
* [An impatient SRE's guide to deleting alerts](../monitoring/deleting-alerts.md)
* [Thanos Compact](../monitoring/thanos-compact.md)
* [Deleting series over a given interval from thanos](../monitoring/thanos-delete-series-interval.md)
* [Stackdriver tracing for the Thanos stack](../monitoring/thanos-tracing.md)
* [Upgrading Monitoring Components](../monitoring/upgrades.md)
* [Session: Application architecture](../onboarding/architecture.md)
* [Gitlab.com on Kubernetes](../onboarding/gitlab.com_on_k8s.md)
* [GPG Keys for Repository Metadata Signing](../packagecloud/manage-repository-metadata-signing-keys.md)
* [GPG Keys for Package Signing](../packaging/manage-package-signing-keys.md)
* [Troubleshooting LetsEncrypt for Pages](../pages/pages-letsencrypt.md)
* [Log analysis on PostgreSQL, Pgbouncer, Patroni and consul Runbook](../patroni/log_analysis.md)
* [Mapping Postgres Statements, Slowlogs, Activity Monitoring and Traces](../patroni/mapping_statements.md)
* [Patroni Cluster Management](../patroni/patroni-management.md)
* [../patroni/performance-degradation-troubleshooting.md](../patroni/performance-degradation-troubleshooting.md)
* [PostgreSQL HA](../patroni/pg-ha.md)
* [../patroni/pg_collect_query_data.md](../patroni/pg_collect_query_data.md)
* [`pg_txid_xmin_age` Saturation Alert](../patroni/pg_xid_xmin_age_alert.md)
* [pgbadger Runbook](../patroni/pgbadger_report.md)
* [../patroni/postgres-checkup.md](../patroni/postgres-checkup.md)
* [Dealing with Data Corruption in PostgreSQL](../patroni/postgres-data-corruption.md)
* [../patroni/postgres.md](../patroni/postgres.md)
* [../patroni/postgresql-backups-wale-walg.md](../patroni/postgresql-backups-wale-walg.md)
* [../patroni/postgresql-locking.md](../patroni/postgresql-locking.md)
* [How to evaluate load from queries](../patroni/postgresql-query-load-evaluation.md)
* [Credential rotation](../patroni/postgresql-role-credential-rotation.md)
* [PostgreSQL subtransactions](../patroni/postgresql-subtransactions.md)
* [PostgreSQL VACUUM](../patroni/postgresql-vacuum.md)
* [Postgresql](../patroni/postgresql.md)
* [Rails SQL Apdex alerts](../patroni/rails-sql-apdex-slow.md)
* [../pgbouncer/patroni-consul-postgres-pgbouncer-interactions.md](../pgbouncer/patroni-consul-postgres-pgbouncer-interactions.md)
* [../pgbouncer/service-pgbouncer.md](../pgbouncer/service-pgbouncer.md)
* [Postgres Replicas](../postgres-dr-delayed/postgres-dr-replicas.md)
* [Praefect Database User Password Rotation](../praefect/praefect-password-rotation.md)
* [Praefect has unavailable repositories](../praefect/praefect-unavailable-repo.md)
* [Redis Cluster](../redis/redis-cluster.md)
* [../redis/redis-functional-partitioning.md](../redis/redis-functional-partitioning.md)
* [A survival guide for SREs to working with Redis at GitLab](../redis/redis-survival-guide-for-sres.md)
* [../redis/redis.md](../redis/redis.md)
* [Container Registry database post-deployment migrations](../registry/db-post-deployment-migrations.md)
* [High Number of Overdue Online GC Tasks](../registry/online-gc-high-overdue-tasks.md)
* [Managing Sentry in Kubernetes](../sentry/sentry.md)
* [A survival guide for SREs to working with Sidekiq at GitLab](../sidekiq/sidekiq-survival-guide-for-sres.md)
* [GET Monitoring Setup](../staging-ref/get-monitoring-setup.md)
* [How to connect to a Database console using Teleport](../teleport/Connect_to_Database_Console_via_Teleport.md)
* [How to connect to a Rails Console using Teleport](../teleport/Connect_to_Rails_Console_via_Teleport.md)
* [Teleport Administration](../teleport/teleport_admin.md)
* [Teleport Approver Workflow](../teleport/teleport_approval_workflow.md)
* [Example Tutorial Template](../tutorials/example_tutorial_template.md)
* [How to use flamegraphs for performance profiling](../tutorials/how_to_use_flamegraphs_for_perf_profiling.md)
* [Life of a Git Request](../tutorials/overview_life_of_a_git_request.md)
* [Life of a Web Request](../tutorials/overview_life_of_a_web_request.md)
* [Tips for writing tutorials](../tutorials/tips_for_tutorial_writing.md)
* [about.gitlab.com](../uncategorized/about-gitlab-com.md)
* [Alert about SSL certificate expiration](../uncategorized/alert-for-ssl-certificate-expiration.md)
* [Blocked user login attempts are high](../uncategorized/blocked-user-logins.md)
* [Canary in GCP production and staging](../uncategorized/canary.md)
* [Domain Registration](../uncategorized/domain-registration.md)
* [GCP Projects](../uncategorized/gcp-project.md)
* [Chef secrets using GKMS](../uncategorized/gkms-chef-secrets.md)
* [GitLab Job Completion](../uncategorized/job_completion.md)
* [Missing Repositories](../uncategorized/missing_repos.md)
* [Omnibus package troubleshooting](../uncategorized/omnibus-package-updates.md)
* [OPS-GITLAB-NET Users and Access Tokens](../uncategorized/ops-gitlab-net-pat.md)
* [../uncategorized/osquery.md](../uncategorized/osquery.md)
* [Periodic Job Monitoring](../uncategorized/periodic_job_monitoring.md)
* [Renaming Nodes](../uncategorized/rename-nodes.md)
* [Shared Configurations](../uncategorized/shared-configurations.md)
* [GitLab staging environment](../uncategorized/staging-environment.md)
* [../uncategorized/subnet-allocations.md](../uncategorized/subnet-allocations.md)
* [Upgrades and Rollbacks of Application Code](../uncategorized/upgrade-and-rollback.md)
* [Access Management for Vault](../vault/access.md)
* [Vault Administration](../vault/administration.md)
* [How to Use Vault for Secrets Management in Infrastructure](../vault/usage.md)
* [version.gitlab.com Runbook](../version/version-gitlab-com.md)
* [Diagnostic Reports](../web/diagnostic-reports.md)
* [Static objects caching](../web/static-objects-caching.md)
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
