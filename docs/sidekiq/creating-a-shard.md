# Creating a Sidekiq Shard

This document will outline the necessary items when considering and building a
new Sidekiq shard.

## Considerations

* If the workers are being proposed to migrate to a new shard, we must ensure we
  have a plan of action to bring online the new shard, and move those workers
  off the old shard.
* If this is a new worker, we should perform a readiness review such that all
  engineers fully understand any implications
* Where possible, we should utilize the new queue routing mechanism to configure
  which workers run where
* We need to understand the workload of this new shard.  This means we need to
  know how the Sidekiq workers operate, their urgency level, the speed of job
  execution, etc.
* Much of the above will be found while working with the appropriate engineering
  team.  Our [documentation for Engineers for
  Sidekiq](https://docs.gitlab.com/ee/development/sidekiq_style_guide.html) is an
  excellent resource.

## Shard Characteristics

With the above information readily available we can then make a few
configuration choices:

* Picking a good obvious name of the shard that will be easy for other SREs to
  interpret the meaning of.
* Develop the appropriate Sidekiq worker configuration/selector query
  * This may be done via tagging our workers in the gitlab code base or via a
    highly sophisticated query.  We should avoid the latter
* How many Pods are necessary?
* If it is safe to utilize the Horizontal Pod Autoscaler, we can set our min
  and max pod values
  * If not, both values would be set to the same number
  * In [runbooks], we need to ensure that we note this shard is not subject to HPA
    saturation
* Attempt to choose the recommended CPU resource requests and Memory resource
  requests and limits

## To Create the Shard

* Modify the necessary items in [runbooks] to ensure the new shard will have it's
  own dedicated metrics.  Includes at least the following:
  * Add an entry in `shards` in metrics-catalog/services/lib/sidekiq-helpers.libsonnet
  * Add a line to `services` in dashboards/delivery/k8s_migration_overview.jsonnet
* Modify the necessary items in [k8s-workloads/gitlab-helmfiles] such that we
  get logs
  * A new section in releases/fluentd/defaults.yaml
* If necessary create a new dedicated node pool
  * Add in terraform; currently in environments/ENV/gke-regional.tf; generally
      look for the other node pool definitions and duplicate/extend
* Modify the necessary items in [k8s-workloads/gitlab-com] adding the new shard
  * Another section in `gitlab.sidekiq.pods` with settings determined above
* Stop the relevant workers running on their previous shard (usually)
  * Add an expression to the selector (or routing config) for the old shard
      to exclude the newly moved workers. Honestly, this is complicated as of
      June 2021. Talk to Craig Miskell if you need help; he'll update these docs
      when <https://gitlab.com/groups/gitlab-com/gl-infra/-/epics/447> and
      <https://gitlab.com/groups/gitlab-com/gl-infra/-/epics/469> are done and
      its all a lot simpler.

[k8s-workloads/gitlab-helmfiles]: https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-helmfiles
[k8s-workloads/gitlab-com]: https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-com
[runbooks]: https://gitlab.com/gitlab-com/runbooks
