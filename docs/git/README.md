<!-- MARKER: do not edit this section directly. Edit services/service-catalog.yml then run scripts/generate-docs -->

**Table of Contents**

[[_TOC_]]

# Git Service

* [Service Overview](https://dashboards.gitlab.net/d/git-main/git-overview)
* **Alerts**: <https://alerts.gitlab.net/#/alerts?filter=%7Btype%3D%22git%22%2C%20tier%3D%22sv%22%7D>
* **Label**: gitlab-com/gl-infra/production~"Service:Git"

## Logging

* [Rails](https://log.gprd.gitlab.net/goto/b368513b02f183a06d28c2a958b00602)
* [Workhorse](https://log.gprd.gitlab.net/goto/3ddd4ee7141ba2ec1a8b3bb0cb1476fe)
* [Puma](https://log.gprd.gitlab.net/goto/a2601cff0b6f000339e05cdb9deab58b)
* [nginx](https://log.gprd.gitlab.net/goto/8a5fb5820ec7c8daebf719c51fa00ce0)
* [Unstructured Rails](https://console.cloud.google.com/logs/viewer?project=gitlab-production&interval=PT1H&resource=gce_instance&advancedFilter=jsonPayload.hostname%3A%22git%22%0Alabels.tag%3D%22unstructured.production%22&customFacets=labels.%22compute.googleapis.com%2Fresource_name%22)
* [system](https://log.gprd.gitlab.net/goto/bd680ccb3c21567e47a821bbf52a7c09)

## Troubleshooting Pointers

* [../bastions/gprd-bastions.md](../bastions/gprd-bastions.md)
* [../bastions/gstg-bastions.md](../bastions/gstg-bastions.md)
* [Blackbox git exporter is down](../blackbox/blackbox-git-exporter.md)
* [../ci-runners/ci_pending_builds.md](../ci-runners/ci_pending_builds.md)
* [Chef Vault Basics](../config_management/chef-vault.md)
* [Chef Tips and Tools](../config_management/chef-workflow.md)
* [../elastic/elasticsearch-integration-in-gitlab.md](../elastic/elasticsearch-integration-in-gitlab.md)
* [Management for forum.gitlab.com](../forum/discourse-forum.md)
* [Blocking and disabling things in the HAProxy load balancers](../frontend/block-things-in-haproxy.md)
* [HAProxy management at GitLab](../frontend/haproxy.md)
* [Possible breach of SSH MaxStartups](../frontend/ssh-maxstartups-breach.md)
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
* [Gitaly Queuing](../gitaly/gitaly-rate-limiting.md)
* [Gitaly repository cgroups](../gitaly/gitaly-repos-cgroup.md)
* [Restoring gitaly data corruption on a project after an unclean shutdown](../gitaly/gitaly-repository-corruption.md)
* [Gitaly unusual activity alert](../gitaly/gitaly-unusual-activity.md)
* [GitLab Storage Re-balancing](../gitaly/storage-rebalancing.md)
* [Git Storage Servers](../gitaly/storage-servers.md)
* [Managing GitLab Storage Shards (Gitaly)](../gitaly/storage-sharding.md)
* [When GitLab.com is down](../incidents/when-gitlab-com-is-down.md)
* [Ad hoc observability tools on Kubernetes nodes](../kube/k8s-adhoc-observability.md)
* [../kube/k8s-oncall-setup.md](../kube/k8s-oncall-setup.md)
* [Kubernetes](../kube/kubernetes.md)
* [Alerting](../monitoring/alerts_manual.md)
* [../monitoring/apdex-alerts-guide.md](../monitoring/apdex-alerts-guide.md)
* [Deleting series over a given interval from thanos](../monitoring/thanos-delete-series-interval.md)
* [Session: Application architecture](../onboarding/architecture.md)
* [Gitlab.com on Kubernetes](../onboarding/gitlab.com_on_k8s.md)
* [Diagnosis with Kibana](../onboarding/kibana-diagnosis.md)
* [Recovering from CI Patroni cluster lagging too much or becoming completely broken](../patroni-ci/recovering_patroni_ci_intense_lagging_or_replication_stopped.md)
* [Custom PostgreSQL Package Build Process for Ubuntu Xenial 16.04](../patroni/custom_postgres_packages.md)
* [Geo Patroni Cluster Management](../patroni/geo-patroni-cluster.md)
* [Patroni Cluster Management](../patroni/patroni-management.md)
* [Pg_repack using gitlab-pgrepack](../patroni/pg_repack.md)
* [How to provision the benchmark environment](../patroni/provisioning_bench_env.md)
* [PgBouncer connection management and troubleshooting](../pgbouncer/pgbouncer-connections.md)
* [Bypass Praefect](../praefect/praefect-bypass.md)
* [Praefect replication is lagging or has stopped](../praefect/praefect-replication.md)
* [Praefect has unavailable repositories](../praefect/praefect-unavailable-repo.md)
* [Redis-Sidekiq catchall workloads reduction](../redis/redis-sidekiq-catchall-workloads-reduction.md)
* [A survival guide for SREs to working with Redis at GitLab](../redis/redis-survival-guide-for-sres.md)
* [../redis/redis.md](../redis/redis.md)
* [Sidekiq Queue Out of Control](../sidekiq/large-sidekiq-queue.md)
* [../sidekiq/silent-project-exports.md](../sidekiq/silent-project-exports.md)
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
* [Terraform Broken Master](../uncategorized/terraform-broken-master.md)
* [How to upload a file to Google Cloud Storage from any system without a credentials configuration](../uncategorized/upload-file-to-gcs-using-signed-url.md)
* [Workers under heavy load because of being used as a CDN](../uncategorized/workers-high-load.md)
* [Configuring and Using the Yubikey](../uncategorized/yubikey.md)
* [Gitaly version mismatch](../version/gitaly-version-mismatch.md)
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
