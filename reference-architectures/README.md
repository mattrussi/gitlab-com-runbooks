 Reference Architecture Monitoring

This directory contains configuration to provide observability into other GitLab instances (not GitLab.com).

This is based off the same Service-Level Monitoring and Saturation Monitoring metrics used to monitor GitLab.com.

Each sub-directory contains a specific reference architecture, although for now, there is only one:

1. [`get-hybrid/`](get-hybrid/): this provides monitoring configuration, dashboards and alerts for a [GitLab Environment Toolkit (GET) Hybrid Kubernetes environment](https://gitlab.com/gitlab-org/quality/gitlab-environment-toolkit/-/blob/main/docs/environment_advanced_hybrid.md).

## Warning about Completeness

This is, at present, a work-in-progress. The plan is to start with a small subset of required metrics and expand it until the configuration covers all metrics critical to the operation of a GitLab instance.

The epic tracking this effort is here: <https://gitlab.com/groups/gitlab-com/-/epics/1721>. For up-to-date progress on the effort, consult the epic.

## How to use

From your chosen reference-architecture sub-directory, deploy:
* `config/prometheus-rules/rules.yml` into your Prometheus
* `config/dashboards/*.json` to Grafana

Details of how to deploy will vary by your chosen configuration management tooling which is beyond the scope of this documentation.

Ensure you are scraping the metrics from all required sub-systems, using the correct job name.  Precise details of what and how to scrape will vary by reference architecture, so the list below is to provide general guidance and commentary without being prescriptive, although it does assume you are using consul with `monitoring_service_discovery` enabled (see https://docs.gitlab.com/ee/administration/monitoring/prometheus/).  You may need to refer to the service definitions (`src/services/*.jsonnet`) to clarify some details.

| Service | Scrape details | Scrape job name required | Notes |
| ------- | -------------- | ------------------------ | ------|
| consul | - | - | - | Looks for pods in the 'consul' namespace; monitoring is kubernetes-level only |
| gitaly | - | `gitaly` consul service | `gitaly` | - |
| gitlab-shell | - | Re-uses praefect metrics | - | This is a weak proxy until gitlab-shell has more accessible metrics (see [runbooks#88](https://gitlab.com/gitlab-com/runbooks/-/issues/88) |
| praefect | - | `praefect` consul service | `praefect` | - |
| registry | - | In kubernetes, the 'registry-prometheus' port | scrape job must be named `praefect` | - |
| sidekiq | - | /metrics  | - | - |
| webservice (rails) | /-/metrics ; in kubernetes, on the `http-webservice` port  | `gitlab-rails` | - |
| webservice (workhorse) | /metrics ; in kubernetes, on the `http-workhorse-exporter` port | `gitlab-rails` | - |
