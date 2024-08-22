<!-- MARKER: do not edit this section directly. Edit services/service-catalog.yml then run scripts/generate-docs -->

**Table of Contents**

[[_TOC_]]

# Topology Service

* [Service Overview](https://dashboards.gitlab.net/d/topology-service-main/topology-service-overview)
* **Alerts**: <https://alerts.gitlab.net/#/alerts?filter=%7Btype%3D%22topology%22%2C%20tier%3D%22sv%22%7D>
* **Label**: gitlab-com/gl-infra/production~"Service::Topology"

## Logging

* []()

## Troubleshooting Pointers

* [../pgbouncer/patroni-consul-postgres-pgbouncer-interactions.md](../pgbouncer/patroni-consul-postgres-pgbouncer-interactions.md)
* [Redis Cluster](../redis/redis-cluster.md)
* [../redis/redis.md](../redis/redis.md)
* [../uncategorized/gcp-network-intelligence.md](../uncategorized/gcp-network-intelligence.md)
<!-- END_MARKER -->

## Summary

The Topology Service implements a limited set of functions responsible for providing essential
features for Cells to operate.

Deployment and service configuration is managed in this [repository](https://gitlab.com/gitlab-com/gl-infra/cells/topology-service-deployer)

Deployment configuration including scaling is managed using a [Runway service manifest](https://docs.runway.gitlab.com/reference/service-manifest/)

Configuration for the service is managed in  uses a config.toml which is setup as an environment variable as part of
deployment. Details on the configuration syntax found [here](https://gitlab.com/gitlab-org/cells/topology-service/-/blob/main/docs/config.md)

## Architecture

Topology service is a Go container deployed using Runway. It sits in its own GCP project and responds
to router requests for information pertaining to Cells.

More detailed documentation found [here](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/cells/topology_service/#architecture)

<!-- ## Performance -->

## Scalability

Topology service is deployed using Runway and it's scaling is handled by Cloud Run and configured as part of Runway deployment [see](https://docs.runway.gitlab.com/reference/scalability/)

## Availability

Topology service is deployed to multiple regions. In future, when storing data, the storage system (Cloud Spanner)
will also be configured in multiple regions.

## Security/Compliance

Currently, no customer data is stored in Cells or in the topology service and is available as a public endpoint

## Monitoring/Alerting

Topology service is deployed using Runway, which [supports observability by integrating with the monitoring stack](https://docs.runway.gitlab.com/reference/observability/). You can see the metrics via the general [Runway Service Metrics dashboard](https://dashboards.gitlab.net/d/runway-service/runway3a-runway-service-metrics).
