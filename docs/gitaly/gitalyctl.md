# `gitalyctl`

[[_TOC_]]

## Introduction

[`gitalyctl`](https://gitlab.com/gitlab-com/gl-infra/woodhouse/-/blob/f3039d33367750c0afbee21a1aa62c0b40cfb2c5/cmd/woodhouse/gitalyctl.go)
implements the [solution
spec](https://gitlab.com/gitlab-com/gl-infra/readiness/-/blob/master/library/gitaly-multi-project/README.md#solution)
to drain git storages.

## Increase throughput of moves

### What is throughput

The main metric for throughput is the increase in the number of GB/s we are moving or the number of moves/s. The best metric we have is the `Success Rate`, the higher it is the faster we are moving repositories

![demo of success rate/s](./img/gitalyctl-success-rate-sec.png)

[source](https://dashboards.gitlab.net/d/gitaly-multi-project-move/gitaly-gitaly-multi-project-move?orgId=1&from=1698077498008&to=1698141553180&viewPanel=16)

### Configuration

When draining storage there are multiple configuration fields to increase the throughput:

1. [`storage.concurrency`](https://gitlab.com/gitlab-com/gl-infra/woodhouse/-/blob/f3039d33367750c0afbee21a1aa62c0b40cfb2c5/configs/gitalyctl-storage-drain-config.example.yml#L6):
    * How many storages from the list it will drain in 1 go.
1. `concurrency`; [Group](https://gitlab.com/gitlab-com/gl-infra/woodhouse/-/blob/f3039d33367750c0afbee21a1aa62c0b40cfb2c5/configs/gitalyctl-storage-drain-config.example.yml#L12), [Snippet](https://gitlab.com/gitlab-com/gl-infra/woodhouse/-/blob/f3039d33367750c0afbee21a1aa62c0b40cfb2c5/configs/gitalyctl-storage-drain-config.example.yml#L19), [Project](https://gitlab.com/gitlab-com/gl-infra/woodhouse/-/blob/f3039d33367750c0afbee21a1aa62c0b40cfb2c5/configs/gitalyctl-storage-drain-config.example.yml#L26)
    * The higher the value the more concurrent moves it will do.
    * The concurrency value is per storage.
1. `move_status_update`; [Group](https://gitlab.com/gitlab-com/gl-infra/woodhouse/-/blob/f3039d33367750c0afbee21a1aa62c0b40cfb2c5/configs/gitalyctl-storage-drain-config.example.yml#L14), [Snippet](https://gitlab.com/gitlab-com/gl-infra/woodhouse/-/blob/f3039d33367750c0afbee21a1aa62c0b40cfb2c5/configs/gitalyctl-storage-drain-config.example.yml#L21), [Project](https://gitlab.com/gitlab-com/gl-infra/woodhouse/-/blob/f3039d33367750c0afbee21a1aa62c0b40cfb2c5/configs/gitalyctl-storage-drain-config.example.yml#L28)
    * This is the frequency at which it checks the move status. The faster it checks, the quicker it can free up a slot to schedule a move for another project. We don't expect this to change a lot currently.
    * Look at the [precentile](https://log.gprd.gitlab.net/app/r/s/hQgAC) to see if we need to reduce this, but it should be well-tuned already.
    * Example: <https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-helmfiles/-/merge_requests/3345#note_1606716477>

### Bottlenecks

1. `sidekiq`: All of the move jobs run on the
   [`gitaly_throttled`](https://dashboards.gitlab.net/d/sidekiq-queue-detail/sidekiq-queue-detail?orgId=1&var-PROMETHEUS_DS=Global&var-environment=gprd&var-stage=main&var-queue=gitaly_throttled).
   This will be the main bottleneck, if you see a large `queue length` it might
   be time to scale up
   [`maxReplicas`](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-com/-/blob/a26c7188f019c79b3f65770be199413bf1c220ff/releases/gitlab/values/gprd.yaml.gotmpl#L670)
    * Risk: One risk of increasing `maxReplicas` is that will be increasing the
      load on the Gitaly servers. So when you increase `maxReplicas` make sure
      you have enough resource capacity in Gitaly.
    * Example: <https://gitlab.com/gitlab-com/gl-infra/reliability/-/issues/24529#note_1601462542>
1. `gitaly`: Both the source and destination storage might end up getting resource saturated, below is a list of resources that get saturated
    * [Disk Read throughput](https://thanos.gitlab.net/graph?g0.expr=max(%0A%20%20rate(node_disk_read_bytes_total%7Benv%3D%22gprd%22%2Cenvironment%3D%22gprd%22%2Cfqdn%3D~%22gitaly-01-stor-gprd.c.gitlab-gitaly-gprd-83fd.internal%22%2Ctype%3D%22gitaly%22%7D%5B1m%5D)%0A)%20by%20(fqdn)%0A&g0.tab=0&g0.stacked=0&g0.range_input=1h&g0.max_source_resolution=0s&g0.deduplicate=1&g0.partial_response=0&g0.store_matches=%5B%5D)
    * [Disk Write throughput](https://thanos.gitlab.net/graph?g0.expr=max(%0A%20%20rate(node_disk_written_bytes_total%7Benv%3D%22gprd%22%2Cenvironment%3D%22gprd%22%2Cfqdn%3D~%22gitaly-01-stor-gprd.c.gitlab-gitaly-gprd-83fd.internal%22%2Ctype%3D%22gitaly%22%7D%5B1m%5D)%0A)%20by%20(fqdn)%0A&g0.tab=0&g0.stacked=0&g0.range_input=1h&g0.max_source_resolution=0s&g0.deduplicate=1&g0.partial_response=0&g0.store_matches=%5B%5D)
    * [CPU scheduling wait](https://thanos.gitlab.net/graph?g0.expr=max%20by%20(fqdn)%20(%0A%20%20rate(node_schedstat_waiting_seconds_total%7Benv%3D%22gprd%22%2Cenvironment%3D%22gprd%22%2Cfqdn%3D~%22gitaly-01-stor-gprd.c.gitlab-gitaly-gprd-83fd.internal%22%2Ctype%3D%22gitaly%22%7D%5B5m%5D)%0A)%0A&g0.tab=0&g0.stacked=0&g0.range_input=1h&g0.max_source_resolution=0s&g0.deduplicate=1&g0.partial_response=0&g0.store_matches=%5B%5D)
    * [CPU](https://thanos.gitlab.net/graph?g0.expr=avg(instance%3Anode_cpu_utilization%3Aratio%7Benv%3D%22gprd%22%2Cenvironment%3D%22gprd%22%2Cfqdn%3D~%22gitaly-01-stor-gprd.c.gitlab-gitaly-gprd-83fd.internal%22%2Ctype%3D%22gitaly%22%7D)%20by%20(fqdn)%0A&g0.tab=0&g0.stacked=0&g0.range_input=1h&g0.max_source_resolution=0s&g0.deduplicate=1&g0.partial_response=0&g0.store_matches=%5B%5D)
