local sliDefinition = import 'gitlab-slis/sli-definition.libsonnet';
local aggregationSet = import 'servicemetrics/aggregation-set.libsonnet';

local list = [
  sliDefinition.new({
    name: 'rails_request_apdex',
    significantLabels: ['endpoint_id', 'feature_category'],
    kind: sliDefinition.apdexKind,
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
