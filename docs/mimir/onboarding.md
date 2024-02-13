# Mimir Onboarding

Mimir is a multi-tenanted system.

This helps us to create soft boundaries by tenant and introduceds a few key benefits:

- Improvied visibility into metric ownership
- Query boundaries and isolated workloads via [shuffle sharding](https://grafana.com/docs/mimir/latest/configure/configure-shuffle-sharding/#about-shuffle-sharding)
- Per tenant limits and cardinality management
- Reduced failure domains in the event of a [query of death](https://grafana.com/docs/mimir/latest/configure/configure-shuffle-sharding/#the-impact-of-a-query-of-death)

## Creating a tenant 

Tenants are provisioned through [config-mgmt](https://ops.gitlab.net/gitlab-com/gl-infra/config-mgmt/-/tree/master/environments/observability-tenants).

Check the [README](https://ops.gitlab.net/gitlab-com/gl-infra/config-mgmt/-/tree/master/environments/observability-tenants#create-tenant) for creating a new tenant.

This helps us to centralise tenants across future observability backends, as well as provide a way to review limit increases or changes.

## Checking Tenant Limits

The [Mimir - Tenants](https://dashboards.gitlab.net/goto/wxzEVa2IR?orgId=1) dashboard will show you tenant specific data, as well as active series and how close you are to limits.

As well as this there is a [Mimir - Overrides](https://dashboards.gitlab.net/goto/iCcUVahSg?orgId=1) dashboard which shows all of the configured default limits and any overrides applied to a given tenant.

Bumping tenant limits is also done through `config-mgmt` and you can see an example [here](https://ops.gitlab.net/gitlab-com/gl-infra/config-mgmt/-/blob/master/environments/observability-tenants/tenants/gitlab-gprd.yaml#L5) as well as an [example MR](https://ops.gitlab.net/gitlab-com/gl-infra/config-mgmt/-/merge_requests/7737).

A full list of tenant overrides is documented [here](https://ops.gitlab.net/gitlab-com/gl-infra/config-mgmt/-/blob/master/environments/observability-tenants/tenants/gitlab-gprd.yaml#L5).

The primary limits tenants will face are:

- `ingestion_rate` - Allowed samples per second
- `max_global_series_per_user` -  Maximum in-memory series allowed in an ingester
- `max_label_names_per_series` - Maximum label names per sent series
