# Service Catalog

More information about the service catalog can be found in the [Service Inventory Catalog page](https://about.gitlab.com/handbook/engineering/infrastructure/library/service-inventory-catalog/).

The `stage-group-mapping.jsonnet` file is generated from
[`stages.yml`](https://gitlab.com/gitlab-com/www-gitlab-com/-/blob/master/data/stages.yml)
in the handbook by running `scripts/update-stage-groups-feature-categories`.

## Teams.yml

The `teams.yml` file can contain a definition of a team responsible
for a certain service or component (SLI). Possible configuration keys
are:

- `product_stage_group`: The name of the stage group, if this team is
  a product stage group defined in [`stages.yml`](https://gitlab.com/gitlab-com/www-gitlab-com/-/blob/master/data/stages.yml).
- `ignored_components`: If the team is a stage group, this key can be
  used to list components that should not feed into the stage group's
  error budget. The recordings for the group will continue for these
  components. But the component will not be included in error budgets
  in infradev reports, Sisense, or dashboards displaying the error
  budget for stage groups.
- `slack_alerts_channel`: The name of the Slack channel (without `#`)
  that the team would like to receive alerts in. Read [more about alerting](../docs/uncategorized/alert-routing.md).
- `send_slo_alerts_to_team_slack_channel`: `true` or `false`. If the
  group would like to receive alerts for [feature
  categories](https://docs.gitlab.com/ee/development/feature_categorization/)
  they own.

## Schema

The service catalog adheres to [JSON Schema](https://json-schema.org/) specification for document annotation and validation. If you are interested in learning more, check out guides for [getting started](https://json-schema.org/learn/getting-started-step-by-step.html).

### Modification

To modify the service catalog format, edit [schema](service-catalog-schema.json) directly. Additional properties are disabled by default, please add new properties sparingly. For dynamic data, consider linking to single source of truth instead.

Right now, versioning is not required. To avoid breaking changes, consider only adding new properties in a backwards compatible manner similar to semantic versioning specification. If a property is no longer needed, please add `DEPRECATED:` prefix to `description` annotation.

### Validation

The service catalog uses [Ajv](https://ajv.js.org/) for schema validation and testing. During CI, tooling is used in `validate` and `test` stages. Here's an example failure:

```json
[
  {
    "instancePath": "/services/0",
    "schemaPath": "#/definitions/ServiceDefinition/required",
    "keyword": "required",
    "params": {
      "missingProperty": "friendly_name"
    },
    "message": "must have required property 'friendly_name'"
  }
]
```

When a failure occurs, address any error messages and push up changes to re-run job.

### Editor Support

One of the benefits of JSON Schema is **optional support** for multiple [editors](https://json-schema.org/implementations.html#editors). If your preferred IDE is supported, follow setup instructions and edit `service-catalog.yml` and/or `teams.yml` as you normally would.

After successful setup, the developer experience should be greatly improved with features such as code completion for properties, hover for annotations, and highlighting for validations. 🚀
