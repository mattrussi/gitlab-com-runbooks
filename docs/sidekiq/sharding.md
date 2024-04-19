
## Sidekiq Sharding

This documents outlines the necessary steps to horizontally shard Sidekiq and migrate workloads to the new Redis instance.

### Background

Sidekiq uses a Redis instance as its backing datastore. However, Redis is not horizontally scalable and Redis Cluster is not suitable for Sidekiq since
there are only a small subset of hot keys.

[Sharding](https://github.com/sidekiq/sidekiq/wiki/Sharding) Sidekiq involves routing jobs to another Redis at the application level.

Gitlab Rails supports this using an application-layer router which was implemented as part of [epic 1218](https://gitlab.com/groups/gitlab-com/gl-infra/-/epics/1218)

Note that "shard" in this document is different from "shard" in the context of [K8s deployments](creating-a-shard.md)

#### Sharding

![Diagram of sharding process](img/sidekiq-sharding-migrator.png)

The first step is to define the routing rules to be routed to a separate Redis. For instance below, the last routing rule will
route jobs to the `queues_shard_catchall_a` instance in the `config/redis.yml`.
All other jobs will be routed to the main Sidekiq Redis defined by `config/redis.queues.yml` or the `queues` key in `config/redis.yml`.

```
sidekiq:
  routingRules:
    - ["worker_name=AuthorizedProjectUpdate::UserRefreshFromReplicaWorker,AuthorizedProjectUpdate::UserRefreshWithLowUrgencyWorker", "quarantine"] # move this to the quarantine shard
    - ["worker_name=AuthorizedProjectsWorker", "urgent_authorized_projects"] # urgent-authorized-projects
    - ["resource_boundary=cpu&urgency=high", "urgent_cpu_bound"] # urgent-cpu-bound
    - ["resource_boundary=memory", "memory_bound"] # memory-bound
    - ["feature_category=global_search&urgency=throttled", "elasticsearch"] # elasticsearch
    - ["resource_boundary!=cpu&urgency=high", "urgent_other"] # urgent-other
    - ["resource_boundary=cpu&urgency=default,low", "low_urgency_cpu_bound"] # low-urgency-cpu-bound
    - ["feature_category=database&urgency=throttled", "database_throttled"] # database-throttled
    - ["feature_category=gitaly&urgency=throttled", "gitaly_throttled"] # gitaly-throttled
    - ["*", "default", "queues_shard_catchall_a"] # catchall on k8s
```

A K8s deployment needs to be created to poll from the extra Sidekiq Redis. This can be done in [k8s-workloads/gitlab-com](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-com/-/blob/master/releases/gitlab/values/gstg.yaml.gotmpl).
Add a new deployment in `sidekiq.pods` with `SIDEKIQ_SHARD_NAME: "queues_shard_catchall_a"` in `extraEnv`.

The routing can be controlled using a feature flag `sidekiq_route_to_<queues_shard_catchall_a or any relevant shard name>`

#### Troubleshooting

This section will cover the issues that are relevant to a Sharded Sidekiq setup. The primary concern is incorrectly job routing which
could lead to dangling/lost jobs.

**Check feature flag**

Checking the feature flag to will determine the state of the router accurately and aid in finding a root cause.

```
/chatops run feature get sidekiq_route_to_<shard_instance_name>
```

**Migrate jobs across instances**

If there are cases of dangling jobs after, one way to resolve it would be to migrate it across instances.
This will require popping the job and enqueuing it in the relevant cluster. This can be done using the Rails console:

```
queue_name = "queue:default"
source = "main"
destination = "queues_shard_catchall_a"

Gitlab::Redis::Queues.instances[source].with do |src|
  while src.llen(queue_name) > 0
    job = src.rpop(queue_name)
    Gitlab::Redis::Queues.instances[destination].with { |c| c.lpush(queue_name, job) }
  end
end
```

**Provision a temporary shard to drain the jobs**

In the event where a steady stream of jobs are being pushed to the incorrect Redis instance, we can create a Sidekiq deployment which
uses the default `redis-sidekiq` for its `Sidekiq.redis` (i.e. no `SIDEKIQ_SHARD_NAME` environment variable). Set the `queues` values for the
deployment to the desired queue.

For example:

```
pods:
  - name: drain
    common:
      labels:
        shard: drain
    concurrency: 10
    minReplicas: 1
    maxReplicas: 10
    podLabels:
      deployment: sidekiq-drain
      shard: drain
    queues: <QUEUE_1>,<QUEUE_2>
    resources:
      requests:
        cpu: 800m
        memory: 2G
      limits:
        cpu: 1.5
        memory: 4G
    extraEnv:
      GITLAB_SENTRY_EXTRA_TAGS: "{\"type\": \"sidekiq\", \"stage\": \"main\", \"shard\": \"drain\"}"
    extraVolumeMounts: |
      - name: sidekiq-shared
        mountPath: /srv/gitlab/shared
        readOnly: false
    extraVolumes: |
      - name: sidekiq-shared
        emptyDir:
          sizeLimit: 10G

```
