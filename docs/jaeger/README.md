<!-- MARKER: do not edit this section directly. Edit services/service-catalog.yml then run scripts/generate-docs -->

**Table of Contents**

[[_TOC_]]

#  Jaeger Service
* [Service Overview](https://dashboards.gitlab.net/d/jaeger-main/jaeger-overview)
* **Alerts**: https://alerts.gitlab.net/#/alerts?filter=%7Btype%3D%22jaeger%22%2C%20tier%3D%22inf%22%7D
* **Label**: gitlab-com/gl-infra/production~"Service:Jaeger"

## Logging

* [Jaeger](TBD)

<!-- END_MARKER -->

## Summary

Jaeger is a distributed tracing system modeled after
[Dapper](https://research.google/pubs/pub36356/). It is intended to replace most
uses of our correlation dashboard as well as
[peek](https://github.com/peek/peek) with a design that is:

* More scaleable: By using Elasticsearch as a backing store.
* More complete: By tracking a sample of all traffic.
* More user-friendly: By providing a cross-service visualization that shows gaps
  in execution.

The primary goal of this system is to aid in understanding system behaviour and
diagnosis of latency.

It provides additional value, such as being a living architecture diagram for
use in onboarding.

Jaeger stores traces consisting of spans, which provide a fine-grained execution
trace of the execution of a single request, through multiple layers of RPCs.
This allows engineers to understand the full end-to-end flow.

## Architecture

The architecture of Jaeger is documented in [the Jaeger docs](https://www.jaegertracing.io/docs/latest/architecture/).

The configuration we are running consists of:

* [labkit](https://gitlab.com/gitlab-org/labkit) and
  [labkit-ruby](https://gitlab.com/gitlab-org/labkit-ruby) as integration points
  between [OpenTracing](https://opentracing.io/), jaeger client libraries, and
  application code.
* Agent: Deployed per-host (and as a DaemonSet in Kubernetes), is a local buffer
  that listens for spans over UDP, batches them up, and forwards them to a
  collector.
* Collector: Running in Kubernetes, this component receives spans from agents
  and writes them to Elasticsearch.
* Query: Running in Kubernetes, this component queries Elasticsearch and
  provides the user-facing UI for Jaeger.
* Elasticsearch: This is the storage backend for the Jaeger system. We run a
  dedicated Elasticsearch cluster for Jaeger in production.

We deploy these components to Kubernetes via
[the Jaeger Operator](https://www.jaegertracing.io/docs/latest/operator/).

The primary tuning parameter in distributed tracing systems is sampling rate.

Because of the high volume of data being collected for any given request, it is
not feasible to track this data for all requests. Instead, a sample of all
traffic is instrumented.

This gives us a lever with which to manage overhead and capacity demands, in
particular storage.

## Performance

If we want to keep tracing always-on, it needs to have a negligible performance
overhead.

This can be accomplished via sampling. Depending on the volume of the incoming
traffic we may want to sample at less than 1%. This configuration is expected
to evolve over time.

Any expensive instrumentation calls must only run when a request is actively
being traced. Since sampling occurs at the head, this information is available
in the request context.

## Scalability

Jaeger is designed as a horizontally scaleable system. The main constraint here
is storage. By storing span data in Elasticsearch, we can scale out the storage
backend as needed.

We target a retention window of 7 days, and will adjust sample rate in
accordance with our budget in order to achieve this window.

Additionally, the collector service is backed by a Kubernetes Horizontal Pod
Autoscaler (HPA), allowing it to respond to increased demand by increasing
capacity.

## Availability

Jaeger stores data on a best-effort basis. Data remains in memory in the
application, is then transferred to the Agent over loopback UDP, and is written
to Elasticsearch by the collector.

We favour availability of the application -- should any of these components
fail, span data may be dropped. This keeps Jaeger out of the critical path.

We have monitoring in place to know when this is occurring.

## Durability

Once data reaches Elasticsearch, we do replicate it, so that it will remain
durable and available for querying.

## Security/Compliance

Fine-grained traces are a vector for data leaks. We sanitize all emitted spans
in an effort to remove PII. This includes removing parameters from Redis and
SQL queries. This redaction logic lives in labkit.

Data in Jaeger is not archived and expires once the retention window has passed.

Access to Jaeger is granted to the Engineering department. It requires the same
access level as logging.

## Monitoring/Alerting

We actively monitor the key components of Jaeger:

* Agent
* Collector
* Query
* Elasticsearch

SRE on-call is alerted on SLO violations.

See also: [the Jaeger grafana
dashboard](https://dashboards.gitlab.net/d/jaeger-main/jaeger-overview).

## Links to further Documentation

* [Jaeger](https://www.jaegertracing.io/docs/latest/)
* [Jaeger Operator](https://www.jaegertracing.io/docs/latest/operator/)
* [Dapper, a Large-Scale Distributed Systems Tracing Infrastructure](https://research.google/pubs/pub36356/)
* [OpenTracing](https://opentracing.io/)
* [OpenTelemetry](https://opentelemetry.io/)
