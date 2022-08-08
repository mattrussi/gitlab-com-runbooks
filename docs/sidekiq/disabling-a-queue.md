# Disabling a Sidekiq queue

When the system in under strain due to job processing, it may be necessary to completely disable a queue so that jobs will queue and not be processed.
To disable a queue it needs to be excluded from the queue selectors,

1. Identify which shard is associated to the queue, the ways to determine this are:
1. Find the queue in the [Shard Overview Dashboard](https://dashboards.gitlab.net/d/sidekiq-shard-detail/sidekiq-shard-detail)
1. Find the `resource_boundary` for the queue [app/workers/all_queues.yml](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/workers/all_queues.yml) or [ee/app/workers/all_queues.yml](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/workers/all_queues.yml) and see which selectors match in [values.yml](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-com/-/blob/master/releases/gitlab/values/values.yaml.gotmpl)
1. Update the selector for excluding the queue, depending on where the queue is located you will need to do the following:
1. If the queue is being processed by catchall on VMs at it to the `EXCLUDED_QUEUE_SELECTORS_PER_ENVIRONMENT` in [sidekiq-queue-configuration.libsonnet](https://ops.gitlab.net/gitlab-cookbooks/chef-repo/-/blob/master/tools/sidekiq-config/sidekiq-queue-configurations.libsonnet)
1. If the queue is being processed by catchall on K8s, remove the queue from [values.yml](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-com/-/blob/master/releases/gitlab/values/values.yaml.gotmpl)
1. If the queue is being processed by one of the other shards in K8s, add a selector `queues: resource_boundary=memory&name!=<queue name>`
