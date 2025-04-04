<!-- MARKER: do not edit this section directly. Edit services/service-catalog.yml then run scripts/generate-docs -->

**Table of Contents**

[[_TOC_]]

# Git Access Service

* [Service Overview](https://dashboards.gitlab.net/d/git-main/git-overview)
* **Alerts**: <https://alerts.gitlab.net/#/alerts?filter=%7Btype%3D%22git%22%2C%20tier%3D%22sv%22%7D>
* **Label**: gitlab-com/gl-infra/production~"Service::Git"

## Logging

* [Rails](https://log.gprd.gitlab.net/goto/b368513b02f183a06d28c2a958b00602)
* [Workhorse](https://log.gprd.gitlab.net/goto/3ddd4ee7141ba2ec1a8b3bb0cb1476fe)
* [Puma](https://log.gprd.gitlab.net/goto/a2601cff0b6f000339e05cdb9deab58b)
* [nginx](https://log.gprd.gitlab.net/goto/8a5fb5820ec7c8daebf719c51fa00ce0)
* [Unstructured Rails](https://console.cloud.google.com/logs/viewer?project=gitlab-production&interval=PT1H&resource=gce_instance&advancedFilter=jsonPayload.hostname%3A%22git%22%0Alabels.tag%3D%22unstructured.production%22&customFacets=labels.%22compute.googleapis.com%2Fresource_name%22)
* [system](https://log.gprd.gitlab.net/goto/bd680ccb3c21567e47a821bbf52a7c09)

## Troubleshooting Pointers

* [ErrorSLOViolation](../alerts/ErrorSLOViolation.md)
* [../bastions/gprd-bastions.md](../bastions/gprd-bastions.md)
* [../bastions/gstg-bastions.md](../bastions/gstg-bastions.md)
* [Blackbox git exporter is down](../blackbox/blackbox-git-exporter.md)
* [Cells and Auto-Deploy](../cells/auto-deploy.md)
* [Cells DNS](../cells/dns.md)
* [../certificates/chef_hybrid.md](../certificates/chef_hybrid.md)
* [../ci-runners/ci_pending_builds.md](../ci-runners/ci_pending_builds.md)
* [../ci-runners/ci-runner-networking.md](../ci-runners/ci-runner-networking.md)
* [Chef Vault Basics](../config_management/chef-vault.md)
* [Chef Tips and Tools](../config_management/chef-workflow.md)
* [../elastic/advanced-search-in-gitlab.md](../elastic/advanced-search-in-gitlab.md)
* [Blocking and Disabling Things in HAProxy](../frontend/block-things-in-haproxy.md)
* [HAProxy Management at GitLab](../frontend/haproxy.md)
* [Possible Breach of SSH MaxStartups](../frontend/ssh-maxstartups-breach.md)
* [Git Stuck Processes](git-stuck-processes.md)
* [Git](git.md)
* [Purge Git data](purge-git-data.md)
* [Workhorse Session Alerts](workhorse-git-session-alerts.md)
* [Find a project from its hashed storage path](../gitaly/find-project-from-hashed-storage.md)
* [Copying or moving a Git repository by hand](../gitaly/git-copy-by-hand.md)
* [../gitaly/git-high-cpu-and-memory-usage.md](../gitaly/git-high-cpu-and-memory-usage.md)
* [Debugging gitaly with gitaly-debug](../gitaly/gitaly-debugging-tool.md)
* [Gitaly is down](../gitaly/gitaly-down.md)
* [Gitaly latency is too high](../gitaly/gitaly-latency.md)
* [Gitaly profiling](../gitaly/gitaly-profiling.md)
* [Gitaly Queuing](../gitaly/gitaly-rate-limiting.md)
* [Gitaly repository cgroups](../gitaly/gitaly-repos-cgroup.md)
* [Restoring gitaly data corruption on a project after an unclean shutdown](../gitaly/gitaly-repository-corruption.md)
* [Gitaly Repository Export](../gitaly/gitaly-repositry-export.md)
* [Gitaly unusual activity alert](../gitaly/gitaly-unusual-activity.md)
* [Gitaly version mismatch](../gitaly/gitaly-version-mismatch.md)
* [`gitalyctl`](../gitaly/gitalyctl.md)
* [Moving repositories from one Gitaly node to another](../gitaly/move-repositories.md)
* [GitLab Storage Re-balancing](../gitaly/storage-rebalancing.md)
* [Managing GitLab Storage Shards (Gitaly)](../gitaly/storage-sharding.md)
* [When GitLab.com is down](../incidents/when-gitlab-com-is-down.md)
* [Ad hoc observability tools on Kubernetes nodes](../kube/k8s-adhoc-observability.md)
* [../kube/k8s-oncall-setup.md](../kube/k8s-oncall-setup.md)
* [Kubernetes](../kube/kubernetes.md)
* [Advisory Database Unresponsive Hosts/Outdated Repositories](../monitoring/advisory_db-unresponsive-hosts.md)
* [Alerting](../monitoring/alerts_manual.md)
* [../monitoring/apdex-alerts-guide.md](../monitoring/apdex-alerts-guide.md)
* [Mixins](../monitoring/mixins.md)
* [Session: Application architecture](../onboarding/architecture.md)
* [Gitlab.com on Kubernetes](../onboarding/gitlab.com_on_k8s.md)
* [Diagnosis with Kibana](../onboarding/kibana-diagnosis.md)
* [Restore Gitaly data on `ops.gitlab.net`](../ops-gitlab-net/gitaly-restore.md)
* [Recovering from CI Patroni cluster lagging too much or becoming completely broken](../patroni-ci/recovering_patroni_ci_intense_lagging_or_replication_stopped.md)
* [Steps to create (or recreate) a Standby CLuster using a Snapshot from a Production cluster as Master cluster (instead of pg_basebackup)](../patroni/build_cluster_from_snapshot.md)
* [Custom PostgreSQL Package Build Process for Ubuntu Xenial 16.04](../patroni/custom_postgres_packages.md)
* [Geo Patroni Cluster Management](../patroni/geo-patroni-cluster.md)
* [Patroni Cluster Management](../patroni/patroni-management.md)
* [Pg_repack using gitlab-pgrepack](../patroni/pg_repack.md)
* [Diagnosing long running transactions](../patroni/postgres-long-running-transaction.md)
* [How to provision the benchmark environment](../patroni/provisioning_bench_env.md)
* [PgBouncer connection management and troubleshooting](../pgbouncer/pgbouncer-connections.md)
* [Redis-Sidekiq catchall workloads reduction](../redis/redis-sidekiq-catchall-workloads-reduction.md)
* [A survival guide for SREs to working with Redis at GitLab](../redis/redis-survival-guide-for-sres.md)
* [../redis/redis.md](../redis/redis.md)
* [How to use flamegraphs for performance profiling](../tutorials/how_to_use_flamegraphs_for_perf_profiling.md)
* [Life of a Git Request](../tutorials/overview_life_of_a_git_request.md)
* [Life of a Web Request](../tutorials/overview_life_of_a_web_request.md)
* [Blocked user login attempts are high](../uncategorized/blocked-user-logins.md)
* [Deleted Project Restoration](../uncategorized/deleted-project-restore.md)
* [GitLab dev environment](../uncategorized/dev-environment.md)
* [../uncategorized/granting-rails-or-db-access.md](../uncategorized/granting-rails-or-db-access.md)
* [Missing Repositories](../uncategorized/missing_repos.md)
* [../uncategorized/namespace-restore.md](../uncategorized/namespace-restore.md)
* [Ruby profiling](../uncategorized/ruby-profiling.md)
* [Shared Configurations](../uncategorized/shared-configurations.md)
* [Terraform Broken Main](../uncategorized/terraform-broken-main.md)
* [How to upload a file to Google Cloud Storage from any system without a credentials configuration](../uncategorized/upload-file-to-gcs-using-signed-url.md)
* [Workers under heavy load because of being used as a CDN](../uncategorized/workers-high-load.md)
* [Configuring and Using the Yubikey](../uncategorized/yubikey.md)
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
