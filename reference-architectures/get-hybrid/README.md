# GitLab GET Hybrid Environment SLO Monitoring

This reference architecture is designed for use within a [GET](https://gitlab.com/gitlab-org/quality/gitlab-environment-toolkit)
Hybrid environment, with Rails and Sidekiq services running inside Kubernetes, and Gitaly running on VMs.

## Further Reading

1. [GET Hybrid Environment](https://gitlab.com/gitlab-org/quality/gitlab-environment-toolkit/-/blob/main/docs/environment_advanced_hybrid.md) documentation.

## Monitored Components

<!-- MARKER: do not edit this section directly. -->
## Service Level Indicators

| **Service** | **Component** | **Description** | **Apdex** | **Error Ratio** | **Operation Rate** |
| ----------- | ------------- | --------------- | --------- | --------------- | ------------------ |
| `gitaly` | `goserver` | This SLI monitors all Gitaly GRPC requests in aggregate, excluding the OperationService. GRPC failures which are considered to be the "server's fault" are counted as errors. The apdex score is based on a subset of GRPC methods which are expected to be fast.  | ✅ SLO: 99.9% | ✅ SLO: 99.95% | ✅ |
| `gitlab-shell` | `grpc_requests` | A proxy measurement of the number of GRPC SSH service requests made to Gitaly and Praefect.  Since we are unable to measure gitlab-shell directly at present, this is the best substitute we can provide.  | ✅ SLO: 99.9% | ✅ SLO: 99.9% | ✅ |
| `logging` | `elasticsearch_searching` | Opensearch global search average rate.  | - | ✅ | ✅ |
| `praefect` | `proxy` | All Gitaly operations pass through the Praefect proxy on the way to a Gitaly instance. This SLI monitors those operations in aggregate.  | ✅ SLO: 99.5% | ✅ SLO: 99.95% | ✅ |
| `praefect` | `replicator_queue` | Praefect replication operations. Latency represents the queuing delay before replication is carried out.  | ✅ SLO: 99.5% | - | ✅ |
| `registry` | `server` | Aggregation of all registry HTTP requests.  | ✅ SLO: 99.7% | ✅ SLO: 99.99% | ✅ |
| `sidekiq` | `email_receiver` | Monitors ratio between all received emails and received emails which could not be processed for some reason.  | - | ✅ SLO: 70% | ✅ |
| `sidekiq` | `shard_catchall` | All Sidekiq jobs  | ✅ SLO: 99.5% | ✅ SLO: 99.5% | ✅ |
| `webservice` | `puma` | Aggregation of most web requests that pass through the puma to the GitLab rails monolith. Healthchecks are excluded.  | ✅ SLO: 99.8% | ✅ SLO: 99.99% | ✅ |
| `webservice` | `workhorse` | Aggregation of most web requests that pass through workhorse, monitored via the HTTP interface. Excludes health, readiness and liveness requests. Some known slow requests, such as HTTP uploads, are excluded from the apdex score.  | ✅ SLO: 99.8% | ✅ SLO: 99.99% | ✅ |
<!-- END_MARKER -->

#### Saturation Monitoring

None yet. Arriving in <https://gitlab.com/gitlab-com/runbooks/-/issues/79>.
