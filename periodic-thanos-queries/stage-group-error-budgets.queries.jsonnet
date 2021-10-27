local periodicQuery = import './periodic-query.libsonnet';
local errorBudget = import 'stage-groups/error_budget.libsonnet';
local datetime = import 'utils/datetime.libsonnet';

local selector = {
  stage: 'main',
  environment: 'gprd',
  monitor: 'global',
};
local aggregationLabels = ['stage_group', 'product_stage'];
local now = std.extVar('current_time');
local midnight = datetime.new(now).beginningOfDay.toString;

{
  stage_group_error_budget_availability: periodicQuery.new({
    query: errorBudget.queries.errorBudgetRatio(selector, aggregationLabels),
    time: midnight,
  }),

  stage_group_error_budget_seconds_spent: periodicQuery.new({
    query: errorBudget.queries.errorBudgetTimeSpent(selector, aggregationLabels),
    time: midnight,
  }),

  stage_group_error_budget_seconds_remaining: periodicQuery.new({
    query: errorBudget.queries.errorBudgetTimeRemaining(selector, aggregationLabels),
    time: midnight,
  }),
}
