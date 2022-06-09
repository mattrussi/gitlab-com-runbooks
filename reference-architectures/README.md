# Reference Architecture Monitoring

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

## Generating a Customized Set of Recording Rules, Alerts, and Dashboards

### Generation Steps

It's possible to customize the configuration of the reference architecture to suit your GitLab deployment.

- Step 1: Clone this repository locally: `git clone git@gitlab.com:gitlab-com/runbooks.git`

- Step 2: Check which version of `jsonnet-tool` is required by consulting the `.tool-versions` file, and install it from <https://gitlab.com/gitlab-com/gl-infra/jsonnet-tool/-/releases>. Alternatively, follow the **Contributor Onboarding** steps in [`README.md`](../README.md#contributor-onboarding) to setup your local development environment. This approach will use `asdf` to install the correct version of `jsonnet-tool` automatically.

- Step 3: create a directory which will contain your local overrides. `mkdir overrides`.

- Step 4: in the `overrides` directory, create an `gitlab-metrics-options.libsonnet` file containing the configuration options. Documentation around possible options is available in the [Options section](#options) later in the documentation. Reviewing the [default options](../libsonnet/reference-architecture-options/validate.libsonnet) can shed light on configuration options available.

```jsonnet
// overrides/gitlab-metrics-options.libsonnet
{
  // Disable praefect
  praefect: {
    enable: false,
  }
}
```

- Step 5: create a directory which will contain your custom recording rules and Grafana dashboards: `mkdir output`.

- Step 6: use the `generate-reference-architecture-config.sh` script to generate your custom configuration.

```shell
# generate a custom configuration, using the `get-hybrid` reference architecture,
# emitting configuration to the `output` directory, and reading overrides from the
# `overrides/` directory.
runbooks/scripts/generate-reference-architecture-config.sh \
    runbooks/reference-architectures/get-hybrid/src/ \
    output/ \
    overrides/
```

- Step 7: install the recording rules from `output/prometheus-rules/rules.yml` into your [Prometheus configuration](https://prometheus.io/docs/prometheus/latest/configuration/recording_rules/). Depending on the deployment, this can be done with the [Kube Prometheus Stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack) helm chart, local file deployment or another means.

- Step 8: install the Grafana dashboards from `output/dashboards/*.json` into your Grafana instance. The means of deployment will depend on the local configuration.

## Options

The following configuration options are available in `gitlab-metrics-options.libsonnet`.

| **Option**        | **Type** | **Default** | **Description** |
| ----------------- | -------- | ----------- | --------------- |
| `praefect.enable` | Boolean  | `true`      | Set to `false` to disable Praefect monitoring. This is usually done when Praefect/Gitaly Cluster is disabled in GitLab Environment Toolkit with `praefect_node_count = 0` |
