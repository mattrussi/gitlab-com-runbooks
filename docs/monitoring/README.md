<!-- MARKER: do not edit this section directly. Edit services/service-catalog.yml then run scripts/generate-docs -->

**Table of Contents**

[[_TOC_]]

# Monitoring Service

* [Service Overview](https://dashboards.gitlab.net/d/monitoring-main/monitoring-overview)
* **Alerts**: <https://alerts.gitlab.net/#/alerts?filter=%7Btype%3D%22monitoring%22%2C%20tier%3D%22inf%22%7D>
* **Label**: gitlab-com/gl-infra/production~"Service:Prometheus"

## Logging

* [system](https://log.gprd.gitlab.net/goto/3a0b51d10d33c9558765e97640acb325)
* [monitoring](https://log.gprd.gitlab.net/goto/09f7c84d5f36e3df0d03382dc350cddf)

## Troubleshooting Pointers

* [How to detect CI Abuse](../ci-runners/ci-abuse-handling.md)
* [../ci-runners/ci_pending_builds.md](../ci-runners/ci_pending_builds.md)
* [design.gitlab.com Runbook](../design/design-gitlab-com.md)
* [../elastic/elasticsearch-integration-in-gitlab.md](../elastic/elasticsearch-integration-in-gitlab.md)
* [Upgrading the OS of Gitaly VMs](../gitaly/gitaly-os-upgrade.md)
* [GitLab.com on Kubernetes](../kube/k8s-new-cluster.md)
* [../kube/k8s-operations.md](../kube/k8s-operations.md)
* [How to resize Persistent Volumes in Kubernetes](../kube/k8s-pvc-resize.md)
* [Service-Level Monitoring](../metrics-catalog/service-level-monitoring.md)
* [Alertmanager Notification Failures](alertmanager-notification-failures.md)
* [Accessing a GKE Alertmanager](alerts_gke.md)
* [Alerting](alerts_manual.md)
* [An impatient SRE's guide to deleting alerts](deleting-alerts.md)
* [prometheus-failed-compactions.md](prometheus-failed-compactions.md)
* [Prometheus pod crashlooping](prometheus-pod-crashlooping.md)
* [Thanos Compact](thanos-compact.md)
* [Upgrading Monitoring Components](upgrades.md)
* [Diagnosis with Kibana](../onboarding/kibana-diagnosis.md)
* [Check the status of transaction wraparound Runbook](../patroni/check_wraparound.md)
* [Log analysis on PostgreSQL, Pgbouncer, Patroni and consul Runbook](../patroni/log_analysis.md)
* [Mapping Postgres Statements, Slowlogs, Activity Monitoring and Traces](../patroni/mapping_statements.md)
* [Postgresql minor upgrade](../patroni/pg_minor_upgrade.md)
* [Pg_repack using gitlab-pgrepack](../patroni/pg_repack.md)
* [../patroni/postgres-checkup.md](../patroni/postgres-checkup.md)
* [../patroni/postgresql-locking.md](../patroni/postgresql-locking.md)
* [How to evaluate load from queries](../patroni/postgresql-query-load-evaluation.md)
* [PostgreSQL VACUUM](../patroni/postgresql-vacuum.md)
* [How to provision the benchmark environment](../patroni/provisioning_bench_env.md)
* [../pgbouncer/patroni-consul-postgres-pgbouncer-interactions.md](../pgbouncer/patroni-consul-postgres-pgbouncer-interactions.md)
* [Add a new PgBouncer instance](../pgbouncer/pgbouncer-add-instance.md)
* [PgBouncer connection management and troubleshooting](../pgbouncer/pgbouncer-connections.md)
* [../redis/redis.md](../redis/redis.md)
* [Container Registry Migration Phase 2](../registry/migration-phase2.md)
* [Sentry is down and gives error 500](../sentry/sentry-is-down.md)
* [A survival guide for SREs to working with Sidekiq at GitLab](../sidekiq/sidekiq-survival-guide-for-sres.md)
* [../spamcheck/index.md](../spamcheck/index.md)
* [GET Monitoring Setup](../staging-ref/get-monitoring-setup.md)
* [../uncategorized/access-gcp-hosts.md](../uncategorized/access-gcp-hosts.md)
* [GitLab Job Completion](../uncategorized/job_completion.md)
* [../uncategorized/osquery.md](../uncategorized/osquery.md)
* [PackageCloud Infrastructure and Backups](../uncategorized/packagecloud-infrastructure.md)
* [Periodic Job Monitoring](../uncategorized/periodic_job_monitoring.md)
* [../uncategorized/subnet-allocations.md](../uncategorized/subnet-allocations.md)
* [version.gitlab.com Runbook](../version/version-gitlab-com.md)
<!-- END_MARKER -->

## Introduction

This document describes the monitoring stack used by gitlab.com. "Monitoring
stack" here implies "metrics stack", concering relatively low-cardinality,
relatively cheap to store metrics that are our primary source of alerting
criteria, and the first port of call for answering "known unknowns" about our
production systems. Events, logs, and traces are out of scope.

We assume some basic familiarity with the [Prometheus](https://prometheus.io/)
monitoring system, and the [Thanos](https://thanos.io/) project, and encourage
you to learn these basics before continuing.

The rest of this document aims to act as a high-level summary of how we use
Prometheus and its ecosystem, but without actually referencing how this
configuration is deployed. For example, we'll describe the job sharding and
service discovery configuration we use without actually pointing to the
configuration management code that puts it into place. Hopefully this allows
those onboarding to understand what's happening without coupling the document to
implementation details.

## Backlog

| Service | Description | Backlog |
|---------|------------|---------|
| ~"Service::Prometheus" | The multiple prometheus servers that we run. | [gl-infra/infrastructure](https://gitlab.com/gitlab-com/gl-infra/reliability/-/issues?scope=all&state=opened&label_name[]=Service%3A%3APrometheus) |
| ~"Service::Thanos" | Anything related to [thanos](https://thanos.io/). | [gl-infra/infrastructure](https://gitlab.com/gitlab-com/gl-infra/reliability/-/issues?scope=all&state=opened&label_name[]=Service%3A%3AThanos) |
| ~"Service::Grafana" | Anything related to <https://dashboards.gitlab.net/> | [gl-infra/infrastructure](https://gitlab.com/gitlab-com/gl-infra/reliability/-/issues?scope=all&state=opened&label_name[]=Service%3A%3AGrafana)
| ~"Service::AlertManager" | Anything related to AlertManager | [gl-infra/infrastructure](https://gitlab.com/gitlab-com/gl-infra/reliability/-/issues?scope=all&state=opened&label_name[]=Service%3A%3AAlertManager)
| ~"Service::Monitoring-Other" | The service we provide to engineers, this covers metrics, labels and anything else that doesn't belong in the services above. | [gl-infra/infrastructure](https://gitlab.com/gitlab-com/gl-infra/reliability/-/issues?scope=all&state=opened&label_name[]=Service%3A%3AMonitoring-Other) |

Some of the issues in the backlog also belong in epics part of the
[Observability Work Queue
Epic](https://gitlab.com/groups/gitlab-com/gl-infra/-/epics/628) to group
issues around a large project that needs to be addressed.

## Querying

Prefer [dashboards](https://dashboards.gitlab.net) to [ad-hoc
queries](https://thanos.gitlab.net), but the latter is of course available.
Prefer Thanos queries to direct Prometheus queries in order to take advantage of
the query cache.

## Dashboards

Grafana dashboards on dashboards.gitlab.net are managed in 3 ways:

1. By hand, editing directly using the Grafana UI
1. Uploaded from <https://gitlab.com/gitlab-com/runbooks/tree/master/dashboards>, either:
   1. json - literally exported from grafana by hand, and added to that repo
   1. jsonnet - JSON generated using jsonnet/grafonnet; see <https://gitlab.com/gitlab-com/runbooks/blob/master/dashboards/README.md>

Grafana dashboards can utilize metrics from a specific Prometheus cluster (e.g. prometheus-app, prometheus-db, ...), but it's preferred to
use the "Global" data source as it points to Thanos which aggregates metrics from all Prometheus instances and it has higher data retention
than any of the regular Prometheus instances.

All dashboards are downloaded/saved automatically into <https://gitlab.com/gitlab-org/grafana-dashboards>, in the dashboards directory.
This happens from the [dashboards exports scheduled pipeline](https://gitlab.com/gitlab-org/grafana-dashboards/-/pipeline_schedules), which runs a Ruby script pulling all dashboards from Grafana and then committing any changes to the git repository.
The repo is also mirror to <https://ops.gitlab.net/gitlab-org/grafana-dashboards>.

## Instrumentation

We pull metrics using various Prometheus servers from Prometheus-compatible
endpoints called "Prometheus exporters". Where direct instrumentation is not
included in a 3rd-party program, as is [the case with
pgbouncer](https://github.com/prometheus-community/pgbouncer_exporter), we
deploy/write adapters in order to be able to ingest metrics into Prometheus.

Probably the most important exporter in our stack is the one in our own
application. GitLab-the-app serves Prometheus metrics on a different TCP port to
that on which it serves the application, a not-uncommon pattern among
directly-instrumented applications.

## Metrics

Without trying to reproduce the excellent Prometheus docs, it is worth briefly
covering the "Prometheus way" of metric names and labels.

A Prometheus metric consists of a name, labels (a set of key-value pairs), and a
floating point value. Prometheus periodically scrapes its configured targets,
ingesting metrics returned by the exporter into its time-series database (TSDB),
stamping them with the current time (unless the metrics are timestamped at
source, a rare use-case). Some examples:

```
http_requests_total{status="200", route="/users/:user_id", method="GET"} 402
http_requests_total{status="404", route="UNKNOWN", method="POST"} 66
memory_in_use_bytes{} 10204000
```

Note the lack of "external" context on each metric. Application authors can add
intuitive instrumentation without worrying about having to relay environmental
context such as which server group it is running in, or whether it's production
or not. Context can be added to metrics in a few places in its lifecycle:

1. At scrape time, by relabeling in Prometheus service discovery configurations.
   1. Kubernetes / GCE labels can be functionally mapped to metric labels using
      custom rules.
   1. Static labels can be applied per scrape-job.
   1. e.g. `{type="gitaly", stage="main", shard="default"}`
   1. We tend to apply our [standard labels](https://gitlab-com.gitlab.io/gl-infra/gitlab-com-engineering/observability/prometheus/label_taxonomy.html#standard-labels)
      at this level.
   1. This adds "external context" to metrics. Hostnames, service types, shards,
      stages, etc.
1. If the metric is the result of a rule (whether recording or alerting), by
   static labels on that rule definition.
   1. e.g. for an alert: `{severity="S1"}`.
1. Static "external labels", applied at the prometheus server level.
   1. e.g. `{env="gprd", monitor="db"}`
   1. These are added by prometheus when a metric is part of an alerting rule,
      and sent to alertmanager, but are not stored in the TSDB and cannot be
      queried.
         * Note that these external labels are additional to the rule-level
           labels that might have already been defined - see point above.
         * There was an open issue on prometheus to change this, but I can't
           find it.
   1. These are also applied by thanos-sidecar (more later) so _are_ exposed to
      thanos queries, and uploaded to the long-term metrics buckets.
   1. Information about which environment an alert originates from can be useful
      for routing alerts: e.g. PagerDuty for production, Slack for
      non-production.

## Scrape jobs

### Service discovery and labels

"Jobs" in Prometheus terminology are instructions to pull ("scrape") metrics
from a set of exporter endpoints. Typically, our GCE Prometheus nodes typically
only monitor jobs that are themselves deployed via Chef to VMs, using static
file service discovery, with the endpoints for each job and their labels
populated by Chef from our Chef inventory.

Our GKE Prometheus nodes typically only monitor jobs deployed to Kubernetes, and
as such use Kubernetes service discovery to build lists of endpoints and map
pod/service labels to Prometheus labels.

### Job partitioning

We run Prometheus in redundant pairs so that we can still scrape metrics and
send alerts when performing rolling updates, and to survive single-node failure.
We run several Prometheus pairs, each with a different set of scrape jobs.

Prometheus can be scaled by partitioning jobs across different instances of it,
and directing queries to the relevant partition (often referred to as a shard).
At the time of writing, our Prometheus partitioning layout is in a state of
flux, due to the ongoing Kubernetes migrations. A given Prometheus partition is
primarily identified by the following 3 external labels:

* **env**: loosely corresponds to a Google project. E.g. gprd, gstg, ops.
  * It can refer to a GitLab SaaS environment (gprd, gstg, pre), our
     operational control plane ("ops"), or an ancilliary production Google
     project like one of the CI ones.
* **monitor**: a Prometheus shard.
  * "app" for GitLab application metrics, "db" for database metrics, and
     "default" for everything else.
* **cluster**: the name of the Kubernetes cluster the Prometheus is running in.
  * not set in GCE shards
  * Note that at the time of writing, we have not yet sharded Prometheus
     intra-cluster. The parts of the core GitLab application that have already
     been migrated to Kubernetes will therefore have monitor=default. This
     situation will likely change faster than this document: remember that the
     metrics are the source of truth.

Note that by definition, if you can see these external labels, you are looking
at a Thanos-derived view (or an alert). If you can't see these external labels,
you're looking at the correct Prometheus already - or you wouldn't have metrics
to look at!

Luckily, it's not quite as common as it sounds to really care where a given
metric comes from. Dashboards and ad-hoc queries via a web console should
usually be satisfied by Thanos, which has a global view of all shards.

#### A note about GitLab CI

GitLab CI jobs run in their own Google Project. This is not peered with our ops
VPC, as a layer of isolation of the arbitrary, untrusted jobs from any
gitlab.com project, from our own infrastructure. There are Prometheus instances
in that project that collect metrics, which have public IPs that only accept
traffic from our gprd Prometheus instances, which federation-scrape metrics from
it. The CI Prometheus instances are therefore not integrated with Thanos or
Alertmanager directly.

CI is undergoing somewhat of an overhaul, so this may well change fast.

## Alerting

### Prometheus rules

We deploy the same set of rules (of both the alerting and recording variety) to
all Prometheus instances. An advantage of this approach is that we get
prod/nonprod parity almost for free, by evaluating the same (alerting) rules and
relying on external labels to distinguish different environments in
Alertmanager's routing tree.

We exploit the fact that rule evaluation on null data is cheap and not an error:
e.g. evaluating rules pertaining to postgresql metrics on non-DB shards still
works, but emits no metrics.

Rules are uploaded to all Prometheus shards from
[here](https://gitlab.com/gitlab-com/runbooks/-/tree/master/rules). This in turn
comes from 2 places:

1. Handwritten rules, in the various files.
1. "Generic" rules, oriented around the [4 golden signals](https://sre.google/sre-book/monitoring-distributed-systems/#xref_monitoring_golden-signals),
   generated from jsonnet by the [metrics-catalog](https://gitlab.com/gitlab-com/runbooks/-/tree/master/metrics-catalog).
      * The metrics catalog is a big topic, please read its own docs linked
        above.

In Chef-managed Prometheus instances, the rules directory is periodically pulled
down by chef-client, and Prometheus reloaded. For Kubernetes, the runbooks
repo's ops mirror pipeline processes the rules directory into a set of
PrometheusRule CRDs, which are pushed to the clusters and picked up by
Prometheus operator.

### thanos-rule

Thanos-rule is a component that evaluates Prometheus rules using data from
thanos-query. Metrics are therefore available from all environments and shards,
and external labels are available.

While we prefer Prometheus rules to Thanos rules, to keep our alerting path as
short and simple as possible, we sometimes have need of thanos-rules when we
need to aggregate rules across Prometheus instances. The most prominent current
example of this is to produce metrics-catalog-generated metrics for our core
application services that are deployed across several zonal GKE clusters, each
monitored by a cluster-local Prometheus. We use thanos rule to aggregate over
the `cluster` external label, to produce latency, traffic, and error rate
metrics for these multi-cluster services.

Rules are defined in [runbooks/thanos-rules](https://gitlab.com/gitlab-com/runbooks/-/tree/master/thanos-rules),
which is populated from jsonnet in [runbooks/thanos-rules-jsonnet](https://gitlab.com/gitlab-com/runbooks/-/tree/master/thanos-rules-jsonnet).

### Alertmanager

We run a single Alertmanager service. It runs in our ops cluster. All Prometheus instances
(and thanos-rule, which can send alerts) make direct connections to each
Alertmanager pod. This is made possible by:

* The use of "VPC-native" GKE clusters, in which pod CIDRs are GCE subnets,
  therefore routable in the same way as VMs.
* We VPC-peer ops to all other VPCs (except CI) in a hub and spoke model.
* The use of [external-dns](https://github.com/kubernetes-sigs/external-dns)
  on a [headless service](https://kubernetes.io/docs/concepts/services-networking/service/#headless-services)
  to allow pod IP service discovery via a public A record.

The alertmanager routing tree is defined in
[runbooks](https://gitlab.com/gitlab-com/runbooks/-/tree/master/alertmanager).

## Scaling Prometheus (Thanos)

In the "Job partitioning" section above we've already discussed how Prometheus'
write/alerting path is sharded by scrape job. This gives us some problems in the
read/query path though:

* Queriers (whether dashboards or ad-hoc via the web console) need to know which
  Prometheus shard will contain a given metric.
* Queries must arbitrarily target one member of a redundant Prometheus pair,
  which may well be missing data from when it was restarted in a rolling
  deployment.
* We can't keep metrics on disk forever, this is expensive. Large indexes
  increase memory pressure on Prometheus

The [Thanos project](https://thanos.io) aims to solve all of these problems:

* A Unified query interface: cross-Prometheus, de-duplicated queries
* Longer-term, cheaper metrics storage: object storage, downsampling of old
  metrics.

We deploy:

* thanos-sidecar
  * colocated with each prometheus instance
  * uploads metrics from TSDB disk to object storage buckets
  * Answers queries from thanos-query, including external labels on metrics so
     that they can be attributed to an environment / shard.
* thanos-query
  * to our ops environment
  * Queries recent metrics from all Prometheus instances (via thanos-sidecar)
  * Queries longer-term metrics from thanos-store.
  * Available for ad-hoc queries at <https://thanos.gitlab.net>.
* thanos-query frontend
  * A service that acts like a load balancing and caching layer for thanos-query.
  * Allows splitting queries into multiple short queries by interval which allows parallelization, prevents large queries from causing OOM, and allows for load balancing.
  * Supports a retry mechanism when queries fail.
  * Allows caching query results, label names, and values and reuses them on subsequent requested queries.
* thanos-store
  * one deployment per bucket, so one per environment / google project
  * Provides a gateway to the metrics buckets populated by thanos-sidecar.
  * These are deployed to each environment separately. Each environment (Google
     project) gets its own bucket.
* thanos-compact
  * a singleton per bucket, so one per environment / google project
  * a background component that builds downsampled metrics and applies
     retention lifecycle rules.
* thanos-rule
  * to our ops environment
  * already discussed in "alerting" above, although evaluates many non-alerting
     rules too.

## meta-monitoring

We must monitor our monitoring stack! This is a nuanced area, and it's easy to
go wrong.

### Cross-shard monitoring

* Within an environment, the default shard in GCE monitors the other shards
  (app, db).
* "Monitors" in this context simply means that we have alerting rules for
  Prometheus being down / not functioning:
  <https://gitlab.com/gitlab-com/runbooks/-/blob/master/rules/default/prometheus-metamons.yml>
* This is in a state of flux: The GKE shard is not part of this type of
  meta-monitoring. A pragmatic improvement would be to have the default-GKE
  shards monitor any other GKE shards ("app" when it exists), and eventually
  turn down the GCE shards by migrating GCE jobs to GKE Prometheus instances.
* All Prometheus instances monitor the Alertmanager: <https://gitlab.com/gitlab-com/runbooks/-/blob/master/rules/alertmanager.yml>
* We similarly monitor thanos components from Prometheus, including thanos-rule
  to catch evaluation failures there.
* There is likely a hole in this setup since we introduced zonal clusters: we
  might not be attuned to monitoring outages there. See
  [issue](https://gitlab.com/gitlab-com/gl-infra/reliability/-/issues/12997).
* Observant readers will have noticed that monitoring Prometheus/Alertmanager is
  all well and good, but if we're failing to send Alertmanager notifications
  then how can we know about it? That brings us to the next section.

### Alerting failure modes

* Our urgent Alertmanager integration is
  [Pagerduty](https://gitlab.pagerduty.com/). When PagerDuty itself is down, we
  have no backup urgent alerting system and rely on online team members noticing
  non-paging pathways such as Slack to tell us of this fact.
* Our less-urgent Alertmanager integrations are Slack, and GitLab issues.
* If Alertmanager is failing to send notifications due to a particular
  integration failing, it will trigger a paging alert. Our paging alerts all
  _also_ go to the Slack integration. In this way we are paged for non-paging
  integration failures, and only Slack-notified of failures to page. This is a
  little paradoxical, but in the absence of a backup paging system this is what
  we can do.
* If Alertmanager is failing to send all notifications, e.g. because it is down,
  we should get a notification from [Dead Man's Snitch](https://deadmanssnitch.com/),
  which is a web service implementation of a dead man's switch.
  * We have always-firing "SnitchHeartBeat" alerts configured on all
       Prometheus shards, with snitches configured for each default shard (both
       GCE and GKE).
  * If a default shard can't check in via the Alertmanager, we'll get
       notified.
  * If the Alertmanager itself is down, all snitches will notify.

### External black-box monitoring

Finally, we also use an external third-party service, Pingdom, to notify us when
certain public services (e.g. gitlab.com) are down to it, as a last line of
defence.

## Architecture

Components diagram from Thanos docs: <https://thanos.io/v0.15/thanos/quick-tutorial.md/#components>

THIS IS WORK IN PROGRESS! IT IS LIKELY TO BE INACCURATE! IT WILL BE UPDATED IN THE NEAR FUTURE!

![monitoring](./img/monitoring.png)

## Performance

## Scalability

## Availability

## Durability

## Security/Compliance

## Monitoring/Alerting

## Links to further Documentation

* ["Prometheus: Up & Running" book](https://www.oreilly.com/library/view/prometheus-up/9781492034131/)
* <https://about.gitlab.com/handbook/engineering/monitoring>
* <https://about.gitlab.com/handbook/engineering/monitoring/#related-videos>
* [A recent "Prometheus 101" video](https://www.youtube.com/watch?v=KXs50X2Td2I) (private, you'll need a "GitLab Unfiltered" Youtube login).
* [Monitoring infrastructure overview](https://youtu.be/HYHQNEB4Rk8)
* [Monitoring infrastructure troubleshooting](https://youtu.be/iiLClqUQjYw)
* [Metrics catalog README](https://gitlab.com/gitlab-com/runbooks/-/blob/master/metrics-catalog/README.md)
* [Apdex alert guide](./apdex-alerts-guide.md)
* [video: delivery: intro to monitoring at gitlab.com](https://www.youtube.com/watch?reload=9&v=fDeeYqCnuoM&list=PL05JrBw4t0KoPzC03-4yXuJEWdUo7VZfX&index=13&t=0s)
* [epic about figuring out and documenting monitoring](https://gitlab.com/groups/gitlab-com/gl-infra/-/epics/75)
* [video: General metrics and anomaly detection](https://www.youtube.com/watch?reload=9&v=Oq5PHtgEM1g&feature=youtu.be)
* [./alerts_manual.md](./alerts_manual.md)
* [./common-tasks.md](./common-tasks.md)
