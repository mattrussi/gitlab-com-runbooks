local sliDefinition = import 'gitlab-slis/sli-definition.libsonnet';
local stages = import 'service-catalog/stages.libsonnet';
local aggregationSet = import 'servicemetrics/aggregation-set.libsonnet';

local list = [
  sliDefinition.new({
    name: 'sidekiq_execution',
    significantLabels: ['worker', 'feature_category', 'urgency', 'external_dependencies', 'queue'],
    kinds: [sliDefinition.apdexKind, sliDefinition.errorRateKind],
    description: |||
      The number of Sidekiq jobs meeting their execution duration target based on the urgency of the worker.
      By default, execution of a job should take no more than 300 seconds. But this can be adjusted by the
      urgency of the worker.

      Read more about this in the [runbooks doc](https://gitlab.com/gitlab-com/runbooks/-/blob/master/docs/sidekiq/sidekiq-slis.md).
    |||,
  }),
  sliDefinition.new({
    name: 'sidekiq_queueing',
    significantLabels: ['worker', 'feature_category', 'urgency', 'external_dependencies', 'queue'],
    kinds: [sliDefinition.apdexKind],
    description: |||
      The number of Sidekiq jobs meeting their queueing duration target based on the urgency of the worker.
      By default, queueing of a job should take no more than 60 seconds. But this can be adjusted by the
      urgency of the worker.

      Read more about this in the [runbooks doc](https://gitlab.com/gitlab-com/runbooks/-/blob/master/docs/sidekiq/sidekiq-slis.md).
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
  names:: std.map(function(sli) sli.name, list),
}
