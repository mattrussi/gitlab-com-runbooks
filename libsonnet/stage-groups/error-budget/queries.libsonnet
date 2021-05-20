local utils = import './utils.libsonnet';
local aggregations = import 'promql/aggregations.libsonnet';
local selectors = import 'promql/selectors.libsonnet';
local durationParser = import 'utils/duration-parser.libsonnet';

local errorBudgetRatio(slaTarget, range, groupSelectors, aggregationLabels) =
  |||
    # Account for missing metrics that are turned into 0 by `vector(0)`.
    clamp_max(
      # Number of successful measurements
      sum by (%(aggregations)s)(
        # Reuest with satisfactory apdex
        sum_over_time(
          gitlab:component:stage_group:execution:apdex:success:rate_1h{%(selectorHash)s}[%(range)s]
        ) or vector(0)
        +
        # Requests without error
        (
          sum_over_time(
            gitlab:component:stage_group:execution:ops:rate_1h{%(selectorHash)s}[%(range)s]
          )
          -
          sum_over_time(
            gitlab:component:stage_group:execution:error:rate_1h{%(selectorHash)s}[%(range)s]
          ) or vector(0)
        )
      )
      /
      # Number of measurements
      sum by (%(aggregations)s)(
        # Apdex Measurements
        sum_over_time(
          gitlab:component:stage_group:execution:apdex:weight:score_1h{%(selectorHash)s}[%(range)s]
        ) or vector(0)
        +
        # Requests
        sum_over_time(
          gitlab:component:stage_group:execution:ops:rate_1h{%(selectorHash)s}[%(range)s]
        )
      ),
    1)
  ||| % {
    selectorHash: selectors.serializeHash(groupSelectors),
    range: range,
    aggregations: aggregations.serialize(aggregationLabels),
  };

local errorBudgetTimeSpent(slaTarget, range, selectors, aggregationLabels) =
  |||
    (
      (
         1 - %(ratioQuery)s
      ) * %(rangeInSeconds)i
    )
  ||| % {
    ratioQuery: errorBudgetRatio(slaTarget, range, selectors, aggregationLabels),
    rangeInSeconds: durationParser.toSeconds(range),
  };

local errorBudgetTimeRemaining(slaTarget, range, selectors, aggregationLabels) =
  |||
    # The number of seconds allowed to be spent in %(range)s
    %(budgetSeconds)i
    -
    %(timeSpentQuery)s
  ||| % {
    range: range,
    budgetSeconds: utils.budgetSeconds(slaTarget, range),
    timeSpentQuery: errorBudgetTimeSpent(slaTarget, range, selectors, aggregationLabels),
  };

{
  init(slaTarget, range): {
    errorBudgetRatio(selectors, aggregationLabels=[]):
      errorBudgetRatio(slaTarget, range, selectors, aggregationLabels),
    errorBudgetTimeSpent(selectors, aggregationLabels=[]):
      errorBudgetTimeSpent(slaTarget, range, selectors, aggregationLabels),
    errorBudgetTimeRemaining(selectors, aggregationLabels=[]):
      errorBudgetTimeRemaining(slaTarget, range, selectors, aggregationLabels),
  },
}
