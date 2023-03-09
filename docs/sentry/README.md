<!-- MARKER: do not edit this section directly. Edit services/service-catalog.yml then run scripts/generate-docs -->

**Table of Contents**

[[_TOC_]]

# Sentry Service

* [Service Overview](https://dashboards.gitlab.net/d/sentry-main/sentry-overview)
* **Alerts**: <https://alerts.gitlab.net/#/alerts?filter=%7Btype%3D%22sentry%22%2C%20tier%3D%22inf%22%7D>
* **Label**: gitlab-com/gl-infra/production~"Service::Sentry"

## Logging

* [system](https://log.gprd.gitlab.net/goto/b4618f79f80f44cb21a32623a275a0e6)

## Troubleshooting Pointers

* [ErrorTracking main troubleshooting document](../errortracking/overview.md)
* [Increased Error Rate](../frontend/high-error-rate.md)
* [Gitaly is down](../gitaly/gitaly-down.md)
* [Tuning and Modifying Alerts](../monitoring/alert_tuning.md)
* [`pg_xid_wraparound` Saturation Alert](../patroni/pg_xid_wraparound_alert.md)
* [../patroni/postgres.md](../patroni/postgres.md)
* [../patroni/postgresql-backups-wale-walg.md](../patroni/postgresql-backups-wale-walg.md)
* [Rotating Rails' PostgreSQL password](../patroni/rotating-rails-postgresql-password.md)
* [Praefect is down](../praefect/praefect-startup.md)
* [Database Connection Pool Saturation](../registry/app-db-conn-pool-saturation.md)
* [High Number of Overdue Online GC Tasks](../registry/online-gc-high-overdue-tasks.md)
* [Sentry general admin troubleshooting](sentry-admin.md)
* [Managing Sentry in Kubernetes](sentry-in-kube.md)
* [Sentry is down and gives error 500](sentry-is-down.md)
* [PostgreSQL PendingWALFilesTooHigh](sentry_pending_wal_files_too_high.md)
* [Pull mirror overdue queue is too large](../sidekiq/large-pull-mirror-queue.md)
* [../sidekiq/sidekiq_error_rate_high.md](../sidekiq/sidekiq_error_rate_high.md)
* [Project exports](../uncategorized/project-export.md)
* [Static objects caching](../web/static-objects-caching.md)
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
