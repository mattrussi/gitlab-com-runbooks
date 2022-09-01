# Statefulset Guidelines

This document will provide a set of guidelines when considering running a
Statefulset inside of a Kubernetes cluster.  To understand what a Statefulset
provides, please refer to [the existing Kubernetes Statefulset
documentation](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)

## Guidelines for future use

* Managing a deployment should ideally be handled via an operator if possible.
  We already have exceptions to this rule in various locations.  An operator is
  usually build by the Maintainers of a project whom have a deep understanding
  of how the service should operate inside of Kubernetes.  If this is not
  achievable, then we should have thorough runbooks indicating how we handle
  various failure scenarios.  The readiness review should indicate why we are
  unable to leverage an operator and how we remediate the lack of one.
* We should understand the performance requirements of disk IO for a given
  service.  GKE provides us with multiple types of storage with varying degrees
  of performance.  We'll want to ensure we choose the correct disk type given
  the requirements of the service.
* We should understand the resource demands of the Pods that provide the
  service.  This will help us determine if we should have a dedicated node pool
  for the given service, or leverage bin packing with minimal interruption to
  existing Pods on the same node.  This will also govern if we need to configure
  the Pods to have a specific [Quality of
  Service](https://kubernetes.io/docs/tasks/configure-pod-container/quality-service-pod/)
  guarantees.
* Understanding the redundancy built into the Statefulset will govern how we
  manage the service.  Having runbooks that describe how to handle various
  failure scenarios will ensure that we understand what we should expect if we
  experience various failure scenarios and any remediation that must be
  accomplished pending the style of failure that we encounter.
* We should understand what is expected if we experience any data loss.
  Dashboards and alerts shall be configured to allow us to understand if we've
  lost data, had some sort of failure, and runbooks should be created such that
  we know how to handle cases where restoration needs to occur and the risks
  involved in these scenarios.
* We should aim to have data loss scenarios taken into account.  Data should
  either be resistant to some sort of system failure or we can lose the data
  without fear of interruption of the service itself.  In the former case, we'll
  want to ensure we fully understand how the service behaves and have runbooks
  that lead us down a path to successful recovery of the data.
* A [readiness-review] is always required to help tease out any use case and
  more thoroughly discuss the above guidelines.

## Current Usage

Statefulsets currently include the following workloads:

* [`fluentd-archvier`](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/tanka-deployments/-/tree/f106d7b79520582c3ce17ea034eab367f4c63716/lib/fluentd)
* [Memcached for Thanos](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/tanka-deployments/-/tree/f106d7b79520582c3ce17ea034eab367f4c63716/lib/memcached)
* [Prometheus](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-helmfiles/-/tree/70ccfc6960b9799bde660c5d7546b237971ddfa2/releases/30-gitlab-monitoring)
* [Thanos Store](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/tanka-deployments/-/tree/f106d7b79520582c3ce17ea034eab367f4c63716/lib/thanos)
* [Some Redis](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/tanka-deployments/-/tree/f106d7b79520582c3ce17ea034eab367f4c63716/lib/redis)
* [Vault](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-helmfiles/-/tree/70ccfc6960b9799bde660c5d7546b237971ddfa2/releases/vault)

### Purpose of Stored Data

* Prometheus - Metrics which are scraped and held locally for short term access
  prior to being stored into a Bucket for long term storage
* Redis - Depends on the instance but this is data written to disk to reduce
  sync times between instances in the case of Pod failure
* Thanos Store - Metrics that are processed between Prometheus and long term
  storage in a Bucket
* Vault - Stores the actual encrypted vault data, multiple Pods provide data
  redundancy
* `fluentd-archiver` - Leveraged for storing buffered data

Of the above, all data is either okay to have been removed, or redundancy is in
place well enough where if a single Pod where to be lost, the service will
continue to operate well.  Along side this, all of these systems are either
managed by an Operator to ensure the Pods are online enough, or there is a
secondary means of ensuring services remain available while part of the
deployment may not be healthy.

## Considerations

* Ensure that if data is lost, it can easily be recovered.  In the above example
  services, if a persistent volume is lost, the data can be replicated by asking
  the service itself to perform this function in the fashion it is already
  designed to do.  In some cases the data may be temporary, or is a cache, thus
  we may see some slowness, but the data can be rebuilt without any
  administrator action.
* Validate that modifications to configurations can be performed in a safe
  manner.  Services not managed by an Operator may lack some controls for
  validating safe configurations protecting us from the quirks of running
  Statefulsets.  Example; We've had some problems during our initial
  implementation of Redis where we were unable to rollback changes made to a
  deployment because the Statefulset was in a bad state.  Manual interaction was
  the only course of action of remediation.  We should attempt to avoid this or
  understand this as much as possible such that we have appropriate CI
  notfications or alerts and runbooks in place to fix incident inducing
  situations.
* Consider the tooling that is built on top of existing services.  Accessing
  services through a VM will vary significantly when inside of Kubernetes.
  Ensure these considerations are taken into place and that the tooling works
  for either infrastructure (example during a migration).
* Consider the resource usage of the Pods themselves.  Does it make sense to add
  the overhead of running a service inside of Kubernetes rather than on a
  Virtual Machine?  Consider any custom tooling, network latency, disk IO
  performance bottlenecks introduced by running the service inside of Kubernetes
  vs. on an VM directly.

## Disclaimer

Statefulsets while no longer considered young in the Kubernetes community
manages instances of a service significantly differently that normal
configuration tooling currently does today.  Updates must be thought about in a
very cautious manner and closely monitored to ensure the intended configuration
is indeed in place.  The majority of nodes that GitLab.com manage data are
normally pretty hefty instances.  The sheer size of an instance may not entirely
make sense as the trade-off's of running an instance with the necessary tooling
replicated inside of Kubernetes is not worth it from a long term value
perspective at this moment in time.  The sheer amount of data being managed may
take advantage of special features available to an Operating System that may not
be widely available to Kubernetes.  Think, kernel level tuning or special
systectl's that tune the Operating System for specific efficiencies that may not
yet be exposed to Kubernetes clusters.  And lastly, we started on Virtual
Machines.  We've built special tooling for these fleets and a large knowledge
base assuming we will continue to leverage on host capabilities.  Moving this to
Kubernetes will certainly involve a lot of work and planning to carry over any
special knowledge, tooling, and new learnings on a differing Infrastructure.

[readiness-review]: https://about.gitlab.com/handbook/engineering/infrastructure/production/readiness/
