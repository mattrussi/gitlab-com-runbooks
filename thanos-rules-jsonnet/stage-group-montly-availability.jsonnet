local aggregations = import 'promql/aggregations.libsonnet';
local errorBudget = import 'stage-groups/error_budget.libsonnet';
local strings = import 'utils/strings.libsonnet';

local ruleGroup = {
  partial_response_strategy: 'warn',
  // Using a long interval, because aggregating 28d worth of data is not cheap,
  // but it also doesn't change fast.
  // Make sure to query these with `last_over_time([ > 30m])`
  interval: '30m',
};
local groupLabels = ['stage_group', 'product_stage'];
local environmentLabels = ['environment'];
local aggregationLabels = groupLabels + environmentLabels;
local selector = {
  // Filtering out staging and canary makes these queries a tiny bit cheaper
  // Aggregating seemed to cause timeouts
  stage: 'main',
  environment: 'gprd',
  monitor: 'global',
};
local rules = {
  groups: [
    ruleGroup {
      name: '28d availability by stage group',
      rules: [{
        record: 'gitlab:stage_group:availability:ratio_28d',
        expr: errorBudget.queries.errorBudgetRatio(selector, aggregationLabels),
      }],
    },
    ruleGroup {
      name: '28d availability by stage group and SLI kind',
      rules: [{
        record: 'gitlab:stage_group:sli_kind:availability:ratio_28d',
        expr: errorBudget.queries.errorBudgetRatio(selector, aggregationLabels + ['sli_kind']),
      }],
    },
    ruleGroup {
      name: '28 traffic share per stage group',
      rules: [{
        record: 'gitlab:stage_group:traffic_share:ratio_28d',
        expr: |||
          (
            %(operationRateByStageGroup)s
          )
          / ignoring(%(groupLabels)s) group_left()
          (
            %(operationRateByEnvironment)s
          )
        ||| % {
          operationRateByStageGroup:
            strings.indent(strings.chomp(errorBudget.queries.errorBudgetOperationRate(selector, aggregationLabels)), 2),
          operationRateByEnvironment:
            strings.indent(strings.chomp(errorBudget.queries.errorBudgetOperationRate(selector, environmentLabels)), 2),
          groupLabels: aggregations.serialize(groupLabels),
        },
      }],
    },
  ],
};


{
  'stage-group-monthly-availability.yml': std.manifestYamlDoc(rules),
}
