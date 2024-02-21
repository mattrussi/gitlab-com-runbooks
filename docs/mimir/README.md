<!-- MARKER: do not edit this section directly. Edit services/service-catalog.yml then run scripts/generate-docs -->

**Table of Contents**

[[_TOC_]]

# Mimir Service

* **Alerts**: <https://alerts.gitlab.net/#/alerts?filter=%7Btype%3D%22mimir%22%2C%20tier%3D%22inf%22%7D>
* **Label**: gitlab-com/gl-infra/production~"Service::Mimir"

## Logging

* [Elasticsearch](https://nonprod-log.gitlab.net/app/r/s/BLV6G)

## Troubleshooting Pointers

* [How to resize Persistent Volumes in Kubernetes](../kube/k8s-pvc-resize.md)
* [Mimir Onboarding](getting-started.md)
* [Mixins](../monitoring/mixins.md)
<!-- END_MARKER -->

<!-- ## Summary -->
## Quick Links

| Reference  | Link  |
|---|---|
| Helm Deployment | [helmfiles](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-helmfiles/-/tree/master/releases/mimir) |
| Tenant Configuration | [config-mgmt](https://ops.gitlab.net/gitlab-com/gl-infra/config-mgmt/-/tree/master/environments/observability-tenants) |
| Runbooks | [Grafana Runbooks](https://grafana.com/docs/mimir/latest/manage/mimir-runbooks/) |
| Dashboards | [Mimir Overview](https://dashboards.gitlab.net/d/ffcd83628d7d4b5a03d1cafd159e6c9c/mimir-overview?orgId=1) |
| Logs | [Elastic Cloud](https://nonprod-log.gitlab.net/app/r/s/h3UsR) |

## Runbooks

We use a slightly refactored version of the [Grafana Monitoring Mixin](https://gitlab.com/gitlab-com/gl-infra/monitoring-mixins) for much of the operational monitoring.

As such the Grafana Runbooks apply to our alerts as well, and are the best source of information for troubleshooting:

* [Grafana Runbooks](https://grafana.com/docs/mimir/latest/manage/mimir-runbooks/)
* [Grafana Dashboards](https://dashboards.gitlab.net/goto/NWm6gahIR?orgId=1)

## Onboarding

See the [getting-started readme](./getting-started.md)

## Cardinality Management

Metrics cardinality is the silent performance killer in Prometheus.

Start with the [cardinality-management readme](./cardinality-management.md) to help identify problem metrics.

<!-- ## Architecture -->

## Architecture

[Architecture Reference](https://grafana.com/docs/mimir/latest/references/architecture/).

We deploy in the [microservices mode](https://grafana.com/docs/mimir/latest/references/architecture/deployment-modes/#microservices-mode) via [helmfiles](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-helmfiles/-/tree/master/releases/mimir).

There are [additional GCP components](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-helmfiles/-/blob/c2ad0ca4a1e4fe85476cfb8601a0f4fa4ee4f54c/releases/mimir/values.yaml.gotmpl#L465) deployed via the helm chart using [config-connector](https://cloud.google.com/config-connector/docs/overview).

This includes storage buckets and IAM policies. These componets are deployed to the `gitlab-observability` GCP project, as this keeps the config connector permissions scoped and blast radius limited to the observability services.

![mimir-architecture](img/mimir-architecture-overview.png)

<!-- ## Performance -->

<!-- ## Scalability -->

## Capacity Planning

There is some good capacity planning docs from Grafana [here](https://grafana.com/docs/mimir/latest/manage/run-production-environment/planning-capacity/#microservices-mode).

These include some guidelines around sizing for various components in Mimir.

Keep in mind that at GitLab we have some incredibly high cardinality metrics, and while these numbers serve as good guidelines we often require more resources than recommended.

<!-- ## Availability -->

<!-- ## Durability -->

<!-- ## Security/Compliance -->

<!-- ## Monitoring/Alerting -->

<!-- ## Links to further Documentation -->
