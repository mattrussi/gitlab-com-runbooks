# Mimir Onboarding

Mimir is a multi-tenanted system.

This helps us to create soft boundaries by tenant and introduces a few key benefits:

- Improved visibility into metric ownership
- Query boundaries and isolated workloads via [shuffle sharding](https://grafana.com/docs/mimir/latest/configure/configure-shuffle-sharding/#about-shuffle-sharding)
- Per tenant limits and cardinality management
- Reduced failure domains in the event of a [query of death](https://grafana.com/docs/mimir/latest/configure/configure-shuffle-sharding/#the-impact-of-a-query-of-death)

## Endpoints

| Region | Endpoint | Internal Endpoint |
| ------ | -------- | ----------------- |
| us-east1 | mimir.ops-gitlab-gke.us-east1.gitlab-ops.gke.gitlab.net | mimir-internal.ops-gitlab-gke.us-east1.gitlab-ops.gke.gitlab.net |

## Creating a tenant

Tenants are provisioned through [config-mgmt](https://ops.gitlab.net/gitlab-com/gl-infra/config-mgmt/-/tree/master/environments/observability-tenants).

Check the [README](https://ops.gitlab.net/gitlab-com/gl-infra/config-mgmt/-/tree/master/environments/observability-tenants#create-tenant) for creating a new tenant.

This helps us to centralise tenants across future observability backends, as well as provide a way to review limit increases or changes.

## Checking Tenant Limits

The [Mimir - Tenants](https://dashboards.gitlab.net/goto/wxzEVa2IR?orgId=1) dashboard will show you tenant specific data, as well as active series and how close you are to limits.

Additionally, there is a [Mimir - Overrides](https://dashboards.gitlab.net/goto/iCcUVahSg?orgId=1) dashboard which shows all of the configured default limits and any overrides applied to a given tenant.

Bumping tenant limits is also done through `config-mgmt` and you can see an example [here](https://ops.gitlab.net/gitlab-com/gl-infra/config-mgmt/-/blob/7a6669d31a8e17b833004f1d0e7b621f9c64e2de/environments/observability-tenants/tenants/gitlab-gprd.yaml#L5) as well as an [example MR](https://ops.gitlab.net/gitlab-com/gl-infra/config-mgmt/-/merge_requests/7737).

A full list of tenant overrides is documented [here](https://grafana.com/docs/mimir/latest/references/configuration-parameters/#limits).

The primary limits tenants will face are:

- `ingestion_rate` - Allowed samples per second
- `max_global_series_per_user` -  Maximum in-memory series allowed in an ingester
- `max_label_names_per_series` - Maximum label names per sent series

## Sending Metrics To Mimir

After you have set up the tenant (or use an existing), you can setup your prometheus client to remote-write metrics
Prometheus configuration is done via the [remote_write config](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#remote_write).

The following example uses the [prometheus-operator](https://github.com/prometheus-operator/prometheus-operator) in kubernetes:

```yaml
remoteWrite:
  - url: <replace_with_mimir_endpoint>
    name: mimir
    basicAuth:
      username:
        name: remote-write-auth
        key: username
      password:
        name: remote-write-auth
        key: password
```

Unfortunately prometheus doesn't support ENV var substitution in the config file, however if using via prometheus-operator it does support a Kubernetes secret reference.
In the above example we point the auth to a secret named `remote-write-auth` and the respending object keys for both `username` and `password`.

Here is an [example config](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-helmfiles/-/blob/7fc52a69894df7e4f635e976668ecb19c962b570/releases/30-gitlab-monitoring/values-instances/ops-gitlab-rw.yaml.gotmpl#L16)

Note that the current usage of htpasswd/basicAuth will be replaced in a future iteration.

For the `url` setting see the [endpoints list](#endpoints).

## Exploring Metrics

Unlike Thanos, Mimir does not have a query UI. Instead it relies on Grafana as its UI for querying.

Within Grafana you can use the [Explore UI](https://grafana.com/docs/grafana/latest/explore/) to run queries.

Select the explore menu item from grafana:

![explore-ui](./img/explure-ui.png)

Ensure you have selected the correct datasource for your tenant:

![explore-ui-datasource-selector](./img/explore-ui-datasource-selector.png)

Query away.

For more information on using the explore ui, you can reference the [Grafana official docs](https://grafana.com/docs/grafana/latest/explore/).
