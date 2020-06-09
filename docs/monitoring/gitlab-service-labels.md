# Service Labeling

We have a series of labels that help identify and relate the observabilty of the underlying service.

* `environment` - The major isolation layer. (E.g. gprd, gstg, ops)
* `shard` - An isolation "bulkhead".
* `stage` - A single deployment version (E.g. main, canary)
* `tier` - A component within a service (E.g. lb, stor, sv)
* `type` - The service identifer (E.g. git, web)

Each of these labels is required on targets in order to correctly attribute them to dashboards and alerts.

## Alert: MissingServiceLabels

There are several places where labels are injected into our infrastrucutre.

### Chef

There is a Chef attribute hash that injects labels into Chef file inventory and Consul inventory.

```ruby
node['prometheus']['labels'] = {
  environment: gprd,
  shard: default,
  stage: main,
  tier: sv,
  type: web,
}
```

These labels are injected in various places due to the nature of Chef attribute management. Many of these are controled at various role levels.

These labels are also included in Consul service attributes automatically.

### Kubernetes

Labeling in Kubernetes is controled in the [k8s-workloads project](https://ops.gitlab.net/gitlab-com/gl-infra/k8s-workloads).
