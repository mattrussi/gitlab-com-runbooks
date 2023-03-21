# GitLab GET Hybrid Environment SLO Monitoring

This reference architecture is designed for use within a [GET](https://gitlab.com/gitlab-org/quality/gitlab-environment-toolkit)
Hybrid environment, with Rails and Sidekiq services running inside Kubernetes, and Gitaly running on VMs.

## Screenshots

Here are some examples of the dashboards generated for this reference architecture.

|                                                         |                                                                |
| ------------------------------------------------------- | -------------------------------------------------------------- |
| **Triage Grafana Dashboard**                            | **Web Service Grafana Dashboard**                              |
| ![Triage Grafana Dashboard](./img/grafana-triage.png)   | ![Web Service Grafana Dashboard](./img/grafana-webservice.png) |
| **Sidekiq Grafana Dashboard**                           | **Gitaly Grafana Dashboard**                                   |
| ![Sidekiq Grafana Dashboard](./img/grafana-sidekiq.png) | ![Gitaly Grafana Dashboard](./img/grafana-gitaly.png)          |

## Diving Deeper

1. [GET Hybrid Environment](https://gitlab.com/gitlab-org/quality/gitlab-environment-toolkit/-/blob/main/docs/environment_advanced_hybrid.md) documentation.
1. [ScaleConf talk describing how these dashboards are generated](https://www.youtube.com/watch?v=2zL9DymXi1E)
1. [Apdex alerts troubleshooting runbook](../../docs/monitoring/apdex-alerts-guide.md)

## Monitored Components

<!-- MARKER:slis: do not edit this section directly. -->
## Service Level Indicators

| **Service** | **Component** | **Description** | **Apdex** | **Error Ratio** | **Operation Rate** |
| ----------- | ------------- | --------------- | --------- | --------------- | ------------------ |
| `gitaly` | `goserver` | This SLI monitors all Gitaly GRPC requests in aggregate, excluding the OperationService. GRPC failures which are considered to be the "server's fault" are counted as errors. The apdex score is based on a subset of GRPC methods which are expected to be fast.  | ✅ SLO: 99.9% | ✅ SLO: 99.95% | ✅ |
| `gitlab-shell` | `grpc_requests` | A proxy measurement of the number of GRPC SSH service requests made to Gitaly and Praefect.  Since we are unable to measure gitlab-shell directly at present, this is the best substitute we can provide.  | ✅ SLO: 99.9% | ✅ SLO: 99.9% | ✅ |
| `praefect` | `proxy` | All Gitaly operations pass through the Praefect proxy on the way to a Gitaly instance. This SLI monitors those operations in aggregate.  | ✅ SLO: 99.5% | ✅ SLO: 99.95% | ✅ |
| `praefect` | `replicator_queue` | Praefect replication operations. Latency represents the queuing delay before replication is carried out.  | ✅ SLO: 99.5% | - | ✅ |
| `registry` | `server` | Aggregation of all registry HTTP requests.  | ✅ SLO: 99.7% | ✅ SLO: 99.99% | ✅ |
| `sidekiq` | `email_receiver` | Monitors ratio between all received emails and received emails which could not be processed for some reason.  | - | ✅ SLO: 70% | ✅ |
| `sidekiq` | `shard_catchall` | All Sidekiq jobs  | ✅ SLO: 99.5% | ✅ SLO: 99.5% | ✅ |
| `webservice` | `puma` | Aggregation of most web requests that pass through the puma to the GitLab rails monolith. Healthchecks are excluded.  | ✅ SLO: 99.8% | ✅ SLO: 99.99% | ✅ |
| `webservice` | `workhorse` | Aggregation of most rails requests that pass through workhorse, monitored via the HTTP interface. Excludes API requests health, readiness and liveness requests. Some known slow requests, such as HTTP uploads, are excluded from the apdex score.  | ✅ SLO: 99.8% | ✅ SLO: 99.99% | ✅ |
| `webservice` | `workhorse_api` | Aggregation of most API requests that pass through workhorse, monitored via the HTTP interface.  The workhorse API apdex has a longer apdex latency than the web to allow for slow API requests.  | ✅ SLO: 99.8% | ✅ SLO: 99.99% | ✅ |
<!-- END_MARKER:slis -->

## Saturation Monitoring

Saturation monitoring is handled differently to the service-level monitoring described above. Each monitored resource is represented as a finite resource with a current value between 0% (unutilized) and 100% (completely saturated). Each saturation resource has a threshold SLO over which it will alert.

<!-- MARKER:saturation: do not edit this section directly. -->
### Monitored Saturation Resources

| **Resource** | **Applicable Services** | **Description** | **Horizontally Scalable?** | **Alerting Threshold** |
| ------------ | ----------------------- | --------------- | -------------------------- | -----------------------|
| `cpu` | `consul`, `gitaly`, `praefect` | This resource measures average CPU utilization across an all cores in a service fleet. If it is becoming saturated, it may indicate that the fleet needs horizontal or vertical scaling.  | ✅ | 90% |
| `disk_inodes` | `consul`, `gitaly`, `praefect` | Disk inode utilization per device per node.  If this is too high, its possible that a directory is filling up with files. Consider logging in an checking temp directories for large numbers of files  | ✅ | 80% |
| `disk_space` | `consul`, `gitaly`, `praefect` | Disk space utilization per device per node.  | ✅ | 90% |
| `go_memory` | `gitaly`, `praefect` | Go's memory allocation strategy can make it look like a Go process is saturating memory when measured using RSS, when in fact the process is not at risk of memory saturation. For this reason, we measure Go processes using the `go_memstat_alloc_bytes` metric instead of RSS.  | ✅ | 98% |
| `kube_container_cpu` | `consul`, `gitlab-shell`, `registry`, `sidekiq`, `webservice` | Kubernetes containers are allocated a share of CPU. When this is exhausted, the container may be thottled.  | ✅ | 99% |
| `kube_container_memory` | `consul`, `gitlab-shell`, `registry`, `sidekiq`, `webservice` | This uses the working set size from cAdvisor for the cgroup's memory usage. That may not be a good measure as it includes filesystem cache pages that are not necessarily attributable to the application inside the cgroup, and are permitted to be evicted instead of being OOM killed.  | ✅ | 90% |
| `kube_container_rss` |  | Records the total anonymous (unevictable) memory utilization for containers for this service, as a percentage of the memory limit as configured through Kubernetes.  This is computed using the container's resident set size (RSS), as opposed to kube_container_memory which uses the working set size. For our purposes, RSS is the better metric as cAdvisor's working set calculation includes pages from the filesystem cache that can (and will) be evicted before the OOM killer kills the cgroup.  A container's RSS (anonymous memory usage) is still not precisely what the OOM killer will use, but it's a better approximation of what the container's workload is actually using. RSS metrics can, however, be dramatically inflated if a process in the container uses MADV_FREE (lazy-free) memory. RSS will include the memory that is available to be reclaimed without a page fault, but not currently in use.  The most common case of OOM kills is for anonymous memory demand to overwhelm the container's memory limit. On swapless hosts, anonymous memory cannot be evicted from the page cache, so when a container's memory usage is mostly anonymous pages, the only remaining option to relieve memory pressure may be the OOM killer.  As container RSS approaches container memory limit, OOM kills become much more likely. Consequently, this ratio is a good leading indicator of memory saturation and OOM risk.  | ✅ | 90% |
| `kube_pool_cpu` | `sidekiq`, `webservice` | This resource measures average CPU utilization across an all cores in the node pool for a service fleet.  If it is becoming saturated, it may indicate that the fleet needs horizontal scaling.  | ✅ | 90% |
| `memory` | `consul`, `gitaly`, `praefect` | Memory utilization per device per node.  | ✅ | 98% |
| `memory_redis_cache` |  | Memory utilization per device per node.   redis-cache has a separate saturation point for this to exclude it from capacity planning calculations.  | ✅ | 98% |
| `node_schedstat_waiting` | `consul`, `gitaly`, `praefect` | Measures the amount of scheduler waiting time that processes are waiting to be scheduled, according to [`CPU Scheduling Metrics`](https://www.robustperception.io/cpu-scheduling-metrics-from-the-node-exporter).  A high value indicates that a node has more processes to be run than CPU time available to handle them, and may lead to degraded responsiveness and performance from the application.  Additionally, it may indicate that the fleet is under-provisioned.  | ✅ | 15% |
| `opensearch_cpu` |  | Average CPU utilization.  This resource measures the CPU utilization for the selected cluster or domain. If it is becoming saturated, it may indicate that the fleet needs horizontal or vertical scaling. The metrics are coming from cloudwatch_exporter.  | ✅ | 80% |
| `opensearch_disk_space` |  | Disk utilization for Opensearch  | ✅ | 75% |
| `single_node_cpu` | `consul`, `gitaly`, `praefect` | Average CPU utilization per Node.  If average CPU is saturated, it may indicate that a fleet is in need to horizontal or vertical scaling. It may also indicate imbalances in load in a fleet.  | ✅ | 95% |
<!-- END_MARKER:saturation -->

## Diving Deeper

1. **[PromCon EU 2019: Practical Capacity Planning Using Prometheus](https://www.youtube.com/watch?v=swnj6KTRg08)**: Presentation at PromCon 2019, describing the way we perform resource saturation monitoring and capacity planning at GitLab.
