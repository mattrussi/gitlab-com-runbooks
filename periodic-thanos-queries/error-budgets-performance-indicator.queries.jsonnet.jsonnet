local periodicQuery = import './periodic-query.libsonnet';
local selectors = import 'promql/selectors.libsonnet';
local datetime = import 'utils/datetime.libsonnet';

local selector = {
  environment: 'gprd',
  monitor: 'global',
};

local now = std.extVar('current_time');
local midnight = datetime.new(now).beginningOfDay.toString;

local completenessIndicatorQuery = |||
  1
  -
  (
    sum(
      sum_over_time(gitlab:component:feature_category:execution:ops:rate_1h{%(selector)s, feature_category=~"not_owned|unknown"}[7d])
    )
    +
    sum(
      sum_over_time(gitlab:component:feature_category:execution:ops:rate_1h{%(selector)s, feature_category!~"not_owned|unknown"}[7d])
      and on (component) gitlab:ignored_component:stage_group
    )
  )
  /
  (
    sum(
      sum_over_time(gitlab:component:feature_category:execution:ops:rate_1h{%(selector)s}[7d])
    )
  )
||| % {
  selector: selectors.serializeHash(selector),
};

{
  stage_group_error_budget_completeness: periodicQuery.new({
    query: completenessIndicatorQuery,
    time: midnight,
  }),
}
