# Statefulset Guidelines

This document will provide a set of guidelines when considering running a
Statefulset inside of a Kubernetes cluster.  To understand what a Statefulset,
please refer to [the existing Kubernetes managed
documentation](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)

## Why we currently shy away

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
Kubernetes will certainly invovle a lot of work and planning to carry over any
special knowledge, tooling, and new learnings on a differing Infrastructure.

## Current Usage

Statefulsets at `$currentCommit` include the following workloads:

* [`fluentd-archvier`](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/tanka-deployments/-/tree/f106d7b79520582c3ce17ea034eab367f4c63716/lib/fluentd)
* [Memcached for Thanos](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/tanka-deployments/-/tree/f106d7b79520582c3ce17ea034eab367f4c63716/lib/memcached)
* [Prometheus](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-helmfiles/-/tree/70ccfc6960b9799bde660c5d7546b237971ddfa2/releases/30-gitlab-monitoring)
* [Thanos Store](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/tanka-deployments/-/tree/f106d7b79520582c3ce17ea034eab367f4c63716/lib/thanos)
* [Some Redis](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/tanka-deployments/-/tree/f106d7b79520582c3ce17ea034eab367f4c63716/lib/redis)
* [Vault](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-helmfiles/-/tree/70ccfc6960b9799bde660c5d7546b237971ddfa2/releases/vault)

### Purpose of Stored Data

* Prometheus - Metrics which are scraped and stored locally for short term
  access prior to being stuffed into a Bucket for long term storage
* Redis - Depends on the instance but this is data written to disk to reduce
  sync times between instances
* Thanos Store - Metrics that are processed between Prometheus and long term
  storage in a Bucket
* Vault - Stores the actual encrypted vault data
* `fluentd-archiver` - Leveraged for storing buffered data

Of the above, all data is either okay to have been removed, or redundancy is in
place well enough where if a single Pod where to be lost, we'll be okay.  Along
side this, all of these systems are either managed by an Operator to ensure the
Pods are online enough, or there is a secondary means of ensuring services
remain available while part of the deployment may not be healthy.

## Guidelines for future use

Consider the following items when thinking of spinning up a Statefulset.

* How is the deployment managed?
* What is the desired performance of the required persistent storage?
* What is the resource demands of the Pods that provide the service?
* What type of redundancy is built into the service?
* What is the worst scenario for the data if the entire cluster or all
  persistent disks are lost?

### Goals to Aim for

* Ensure that if data is lost, it can easily be recovered.  In the above example
  services, if a persistent volume is lost, the data can be replicated by asking
  the service itself to perform this function in the fashion it is already
  designed to do.  In some cases the data may be temporary, or is a cache, thus
  we may see some slowness, but the data can be rebuilt without any
  administrator action.
* Validate that modifications to configurations can be performed in a safe
  manner.  Services not managed by an Operator may lack some controls for
  validating safe configurations protecting us from the quirks of running
  Statefulsets.  We've had some problems during our initial implementation of
  Redis where we were unable to rollback changes made to a deployment because
  the Statefulset was in a bad state.  Manual interaction was the only course of
  action of remediation.  We should attempt to avoid this or understand this as
  much as possible such that we have appropriate runbooks in place to fix
  incident inducing situations.
* Consider the tooling that is built on top of existing services.  Accessing
  services not through a VM will vary significantly inside of Kubernetes.
  Ensure these considerations are taken into place and that the tooling works
  for either infrastructure (example during a migration).
* Consider the resource usage of the Pods themselves.  Does it make sense to add
  the overhead of running a service inside of Kubernetes rather than on a
  Virtual Machine?  Consider any custom tooling, network latency, disk IO
  performance bottlenecks introduced by running inside of Kubernetes vs on an VM
  directly.
* As always, a [readiness-review] is always highly encouraged to help tease out
  any use case and answer some of the above questions.

[readiness-review]: https://about.gitlab.com/handbook/engineering/infrastructure/production/readiness/
