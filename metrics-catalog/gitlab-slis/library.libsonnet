local sliDefinition = import 'gitlab-slis/sli-definition.libsonnet';
local aggregationSet = import 'servicemetrics/aggregation-set.libsonnet';

local list = [
  sliDefinition.new({
    name: 'rails_request_apdex',
    significantLabels: ['endpoint_id', 'feature_category', 'request_urgency'],
    kind: sliDefinition.apdexKind,
    description: |||
      The number of requests meeting their duration target based on the urgency
      of the endpoint. By default, a request should take no more than 1s. But
      this can be adjusted by endpoint.

      Read more about this in the [documentation](https://docs.gitlab.com/ee/development/application_slis/rails_request_apdex.html).
    |||,
  }),
  sliDefinition.new({
    name: 'graphql_query_apdex',
    significantLabels: ['endpoint_id', 'feature_category', 'query_urgency'],
    kind: sliDefinition.apdexKind,
    description: |||
      The number of GraphQL queries meeting their duration target based on the urgency
      of the endpoint. By default, a query should take no more than 1s. We're working
      on making the urgency customizable in [this epic](https://gitlab.com/groups/gitlab-org/-/epics/5841).

      Mutliple queries could be batched inside a single request.
    |||,
  }),
  sliDefinition.new({
    name: 'customers_dot_requests_apdex',
    significantLabels: ['endpoint_id'],
    kind: sliDefinition.apdexKind,
    feature_category: 'fulfillment_platform',
    description: |||
      The number of CustomersDot requests meeting their duration target based on the urgency
      of the endpoint. By default, a request should take no more than 0.5s. But
      this can be adjusted by endpoint.
    |||,
  }),
];

local definitionsByName = std.foldl(
  function(memo, definition)
    assert !std.objectHas(memo, definition.name) : '%s already defined' % [definition.name];
    memo { [definition.name]: definition },
  list,
  {}
);

{
  get(name):: definitionsByName[name],
  all:: list,
}
