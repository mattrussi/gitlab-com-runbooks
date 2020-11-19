# Service Catalog

More information about the service catalog can be found in the [Service Inventory Catalog page](https://about.gitlab.com/handbook/engineering/infrastructure/library/service-inventory-catalog/).

This file is consumed by the [service catalog app](https://gitlab.com/gitlab-com/gl-infra/service-catalog-app)
in order to generate the [service catalog website](https://us-central1-gitlab-infra-automation-stg.cloudfunctions.net/ui/services).

The `stage-group-mapping.jsonnet` file is generated from
[`stages.yml`](https://gitlab.com/gitlab-com/www-gitlab-com/-/blob/master/data/stages.yml)
in the handbook by running `scripts/update-stage-groups-feature-categories`.
