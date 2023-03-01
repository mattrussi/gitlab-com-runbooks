<!-- MARKER: do not edit this section directly. Edit services/service-catalog.yml then run scripts/generate-docs -->

**Table of Contents**

[[_TOC_]]

# Web Service

* [Service Overview](https://dashboards.gitlab.net/d/web-main/web-overview)
* **Alerts**: <https://alerts.gitlab.net/#/alerts?filter=%7Btype%3D%22web%22%2C%20tier%3D%22sv%22%7D>
* **Label**: gitlab-com/gl-infra/production~"Service::Web"

## Logging

* [Rails](https://log.gprd.gitlab.net/goto/15b83f5a97e93af2496072d4aa53105f)
* [Workhorse](https://log.gprd.gitlab.net/goto/464bddf849abfd4ca28494a04bad3ead)
* [Kubernetes](https://log.gprd.gitlab.net/goto/88eab835042a07b213b8c7f24213d5bf)

## Troubleshooting Pointers

* [How to connect to a Database console using Teleport](../Teleport/Connect_to_Database_Console_via_Teleport.md)
* [How to connect to a Rails Console using Teleport](../Teleport/Connect_to_Rails_Console_via_Teleport.md)
* [Teleport Approver Workflow](../Teleport/teleport_approval_workflow.md)
* [../ci-runners/service-ci-runners.md](../ci-runners/service-ci-runners.md)
* [Cloudflare: Managing Traffic](../cloudflare/managing-traffic.md)
* [Cloudflare for the on-call](../cloudflare/oncall.md)
* [Service Locations](../cloudflare/services-locations.md)
* [CloudFlare Troubleshooting](../cloudflare/troubleshooting.md)
* [Chef Guidelines](../config_management/chef-guidelines.md)
* [Chef Tips and Tools](../config_management/chef-workflow.md)
* [Interacting with Consul](../consul/interaction.md)
* [CustomersDot main troubleshoot documentation](../customersdot/overview.md)
* [../elastic/elastic-cloud.md](../elastic/elastic-cloud.md)
* [../elastic/kibana.md](../elastic/kibana.md)
* [Management for forum.gitlab.com](../forum/discourse-forum.md)
* [Frontend (HAProxy) Logging](../frontend/haproxy-logging.md)
* [HAProxy management at GitLab](../frontend/haproxy.md)
* [Deploying a change to gitlab.rb](../git/deploy-gitlab-rb-change.md)
* [GitLab Hosted CodeSandbox](../git/gitlab-hosted-codesandbox.md)
* [../gitaly/git-high-cpu-and-memory-usage.md](../gitaly/git-high-cpu-and-memory-usage.md)
* [Gitaly is down](../gitaly/gitaly-down.md)
* [Gitaly latency is too high](../gitaly/gitaly-latency.md)
* [Gitaly profiling](../gitaly/gitaly-profiling.md)
* [Gitaly unusual activity alert](../gitaly/gitaly-unusual-activity.md)
* [Git Storage Servers](../gitaly/storage-servers.md)
* [Kubernetes-Agent Basic Troubleshooting](../kas/kubernetes-agent-basic-troubleshooting.md)
* [../kube/k8s-oncall-setup.md](../kube/k8s-oncall-setup.md)
* [Scaling Elastic Cloud Clusters](../logging/scaling.md)
* [Alertmanager Notification Failures](../monitoring/alertmanager-notification-failures.md)
* [../monitoring/apdex-alerts-guide.md](../monitoring/apdex-alerts-guide.md)
* [../monitoring/common-tasks.md](../monitoring/common-tasks.md)
* [Service Error Rate](../monitoring/definition-service-error-rate.md)
* [Service Operation Rate](../monitoring/definition-service-ops-rate.md)
* [Prometheus Empty Service Discovery](../monitoring/prometheus-empty-sd.md)
* [Session: Application architecture](../onboarding/architecture.md)
* [Diagnosis with Kibana](../onboarding/kibana-diagnosis.md)
* [../patroni/database_peak_analysis.md](../patroni/database_peak_analysis.md)
* [Geo Patroni Cluster Management](../patroni/geo-patroni-cluster.md)
* [../patroni/pg_collect_query_data.md](../patroni/pg_collect_query_data.md)
* [../patroni/postgres.md](../patroni/postgres.md)
* [../patroni/postgresql-backups-wale-walg.md](../patroni/postgresql-backups-wale-walg.md)
* [PostgreSQL VACUUM](../patroni/postgresql-vacuum.md)
* [How to provision the benchmark environment](../patroni/provisioning_bench_env.md)
* [../pgbouncer/patroni-consul-postgres-pgbouncer-interactions.md](../pgbouncer/patroni-consul-postgres-pgbouncer-interactions.md)
* [PgBouncer connection management and troubleshooting](../pgbouncer/pgbouncer-connections.md)
* [Sidekiq or Web/API is using most of its PgBouncer connections](../pgbouncer/pgbouncer-saturation.md)
* [A survival guide for SREs to working with Redis at GitLab](../redis/redis-survival-guide-for-sres.md)
* [../redis/redis.md](../redis/redis.md)
* [Managing Sentry in Kubernetes](../sentry/sentry-in-kube.md)
* [Sentry is down and gives error 500](../sentry/sentry-is-down.md)
* [A survival guide for SREs to working with Sidekiq at GitLab](../sidekiq/sidekiq-survival-guide-for-sres.md)
* [../spamcheck/index.md](../spamcheck/index.md)
* [Example Tutorial Template](../tutorials/example_tutorial_template.md)
* [How to use flamegraphs for performance profiling](../tutorials/how_to_use_flamegraphs_for_perf_profiling.md)
* [Life of a Git Request](../tutorials/overview_life_of_a_git_request.md)
* [Life of a Web Request](../tutorials/overview_life_of_a_web_request.md)
* [Blocked user login attempts are high](../uncategorized/blocked-user-logins.md)
* [Debug failed chef provisioning](../uncategorized/debug-failed-chef-provisioning.md)
* [Domain Registration](../uncategorized/domain-registration.md)
* [Gemnasium is down](../uncategorized/gemnasium_is_down.md)
* [Project exports](../uncategorized/project-export.md)
* [Ruby profiling](../uncategorized/ruby-profiling.md)
* [Setup oauth2-proxy protection for web based application](../uncategorized/setup-oauth2-proxy-protected-application.md)
* [How to Use Vault for Secrets Management in Infrastructure](../vault/usage.md)
* [Vault Secrets Management](../vault/vault.md)
* [Workhorse Image Scaler](workhorse-image-scaler.md)
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
