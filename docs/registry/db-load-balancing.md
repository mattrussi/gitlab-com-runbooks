# Container Registry Database Load Balancing

**Table of Contents**

[TOC]

## Background

The Container Registry supports database load balancing. This feature is implemented as described in the [technical specification](https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/spec/gitlab/database-load-balancing.md).

For now, this feature is only available on Staging. You can follow [Container Registry: Database Load Balancing (DLB) (&8591)](https://gitlab.com/groups/gitlab-org/-/epics/8591) for more updates. The rollout plan being followed is detailed [here](https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/spec/gitlab/database-load-balancing.md?ref_type=heads#rollout-plan).

## Alerts

- [`ContainerRegistryDBLoadBalancerReplicaPoolSize`](./alerts/ContainerRegistryDBLoadBalancerReplicaPoolSize.md)
- [`PatroniRegistryServiceDnsLookupsApdexSLOViolation`](./alerts/PatroniRegistryServiceDnsLookupsApdexSLOViolation.md)

## Logs

The list of log entries emitted by the registry is documented [here](https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/spec/gitlab/database-load-balancing.md?ref_type=heads#logging).

To find all relevant log entries, you can filter logs by `json.msg: "replica" or "replicas" or "LSN"` ([example](https://nonprod-log.gitlab.net/app/r/s/J4dYB)).

## Metrics

The list of Prometheus metrics emitted by the registry is documented [here](https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/spec/gitlab/database-load-balancing.md?ref_type=heads#metrics).

There are graphs for all relevant metrics in the [registry: Database Detail](https://dashboards.gitlab.net/goto/ulhoLB7NR?orgId=1) dashboard, under a dedicated `Load Balancing` row.

# Related Links

- [Feature epic](https://gitlab.com/groups/gitlab-org/-/epics/8591)
- [Technical specification](https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/spec/gitlab/database-load-balancing.md)
