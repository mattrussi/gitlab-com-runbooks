# Container Registry Database Load Balancing

**Table of Contents**

[TOC]

## Background

The Container Registry supports database load balancing. This feature is implemented as described in the [technical specification](https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/spec/gitlab/database-load-balancing.md).

For now this feature is only available on Staging. You can follow [Container Registry: Database Load Balancing (DLB) (&8591)](https://gitlab.com/groups/gitlab-org/-/epics/8591) for more updates.

## Alerts

- [`ContainerRegistryDBLoadBalancerReplicaPoolSize`](./alerts/ContainerRegistryDBLoadBalancerReplicaPoolSize.md)
- [`PatroniRegistryServiceDnsLookupsApdexSLOViolation`](./alerts/PatroniRegistryServiceDnsLookupsApdexSLOViolation.md)
