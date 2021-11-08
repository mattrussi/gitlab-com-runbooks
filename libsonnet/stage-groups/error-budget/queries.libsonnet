local utils = import './utils.libsonnet';
local aggregations = import 'promql/aggregations.libsonnet';
local labels = import 'promql/labels.libsonnet';
local selectors = import 'promql/selectors.libsonnet';
local durationParser = import 'utils/duration-parser.libsonnet';
local strings = import 'utils/strings.libsonnet';

local ignoredComponentJoinLabels = ['stage_group', 'component'];
local ignoreCondition(ignoreComponents) =
  if ignoreComponents then
    'unless on (%s) gitlab:ignored_component:stage_group' % [aggregations.serialize(ignoredComponentJoinLabels)]
  else
    '';

local errorBudgetRatio(range, groupSelectors, aggregationLabels, ignoreComponents) =
  |||
    clamp_max(
      sum by (%(aggregations)s)(
        sum by (%(aggregationsIncludingComponent)s) (
          label_replace(
            sum_over_time(
              gitlab:component:stage_group:execution:apdex:success:rate_1h{%(selectorHash)s}[%(range)s]
            ), 'sli_kind', 'apdex', '', ''
          )
          or
          label_replace(
            sum by(%(aggregations)s) (
              sum_over_time(
                gitlab:component:stage_group:execution:ops:rate_1h{%(selectorHash)s}[%(range)s]
              )
            )
            -
            sum by(%(aggregations)s) (
              sum_over_time(
                gitlab:component:stage_group:execution:error:rate_1h{%(selectorHash)s}[%(range)s]
              )
            ), 'sli_kind', 'error', '', ''
          )
        ) %(ignoreCondition)s
      )
      /
      sum by (%(aggregations)s)(
        sum by (%(aggregationsIncludingComponent)s) (
          label_replace(
            sum_over_time(
              gitlab:component:stage_group:execution:apdex:weight:score_1h{%(selectorHash)s}[%(range)s]
            ),
            'sli_kind', 'apdex', '', ''
          )
          or
          label_replace(
            sum_over_time(
              gitlab:component:stage_group:execution:ops:rate_1h{%(selectorHash)s}[%(range)s]
            ),
            'sli_kind', 'error', '', ''
          )
        ) %(ignoreCondition)s
      ),
    1)
  ||| % {
    selectorHash: selectors.serializeHash(groupSelectors),
    range: range,
    aggregations: aggregations.serialize(aggregationLabels),
    aggregationsIncludingComponent: aggregations.serialize(aggregationLabels + ignoredComponentJoinLabels),
    ignoreCondition: ignoreCondition(ignoreComponents),
  };

local errorBudgetTimeSpent(range, selectors, aggregationLabels, ignoreComponents) =
  |||
    (
      (
         1 - %(ratioQuery)s
      ) * %(rangeInSeconds)i
    )
  ||| % {
    ratioQuery: errorBudgetRatio(range, selectors, aggregationLabels, ignoreComponents),
    rangeInSeconds: durationParser.toSeconds(range),
  };

local errorBudgetTimeRemaining(slaTarget, range, selectors, aggregationLabels, ignoreComponents) =
  |||
    # The number of seconds allowed to be spent in %(range)s
    %(budgetSeconds)i
    -
    %(timeSpentQuery)s
  ||| % {
    range: range,
    budgetSeconds: utils.budgetSeconds(slaTarget, range),
    timeSpentQuery: errorBudgetTimeSpent(range, selectors, aggregationLabels, ignoreComponents),
  };

local errorBudgetRateAggregationInterpolation(range, groupSelectors, aggregationLabels, ignoreComponents) =
  local filteredAggregationLabels = std.filter(
    function(label) label != 'violation_type',
    aggregationLabels
  );
  {
    aggregationLabels: aggregations.join(filteredAggregationLabels),
    selectors: selectors.serializeHash(groupSelectors),
    range: range,
    ignoreCondition: ignoreCondition(ignoreComponents),
    aggregationsIncludingComponent: aggregations.join(filteredAggregationLabels + ignoredComponentJoinLabels),
  };

local errorBudgetViolationRate(range, groupSelectors, aggregationLabels, ignoreComponents) =
  local partsInterpolation = errorBudgetRateAggregationInterpolation(range, groupSelectors, aggregationLabels, ignoreComponents);
  local apdexViolationRate = |||
    sum by (%(aggregationLabels)s)(
      sum by (%(aggregationsIncludingComponent)s)(
        sum_over_time(
          gitlab:component:stage_group:execution:apdex:weight:score_1h{%(selectors)s}[%(range)s]
        ) -
        # Request with satisfactory apdex
        sum_over_time(
          gitlab:component:stage_group:execution:apdex:success:rate_1h{%(selectors)s}[%(range)s]
        )
      ) %(ignoreCondition)s
    )
  ||| % partsInterpolation;
  local errorRate = |||
    sum by (%(aggregationLabels)s)(
      sum by (%(aggregationsIncludingComponent)s)(
        sum_over_time(
          gitlab:component:stage_group:execution:error:rate_1h{%(selectors)s}[%(range)s]
        )
      ) %(ignoreCondition)s
    )
  ||| % partsInterpolation;

  // We're calculating an absolute number of failures from a failure rate
  // this means we don't have an exact precision, but only a request per second
  // number that we turn into an absolute number. To display a number of requests
  // over multiple days, the decimals don't matter anymore, so we're rounding them
  // up using `ceil`.
  //
  // The per-second-rates are sampled every minute, we assume that we continue
  // to receive the same number of requests per second until the next sample.
  // So we multiply the rate by the number of samples we don't have.
  // For example: the last sample said we were processing 2RPS, next time we'll
  // take a sample will be in 60s, so in that time we assume to process
  // 60 * 2 = 120 requests.
  // https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/1123
  |||
    ceil(
      (
        sum by (%(aggregationLabelsWithViolationType)s) (
          %(apdexViolationRate)s
          or
          %(errorRate)s
        ) > 0
      ) * 60
    )
  ||| % {
    aggregationLabelsWithViolationType: aggregations.join(aggregationLabels),
    apdexViolationRate: strings.indent(labels.addStaticLabel('violation_type', 'apdex', apdexViolationRate), 6),
    errorRate: strings.indent(labels.addStaticLabel('violation_type', 'error', errorRate), 6),
  };

local errorBudgetOperationRate(range, groupSelectors, aggregationLabels, ignoreComponents) =
  local partsInterpolation = errorBudgetRateAggregationInterpolation(range, groupSelectors, aggregationLabels, ignoreComponents);
  local apdexOperationRate = |||
    sum by (%(aggregationLabels)s)(
      sum by (%(aggregationsIncludingComponent)s)(
        sum_over_time(
          gitlab:component:stage_group:execution:apdex:weight:score_1h{%(selectors)s}[%(range)s]
        )
      ) %(ignoreCondition)s
    )
  ||| % partsInterpolation;
  local errorOperationRate = |||
    sum by (%(aggregationLabels)s)(
      sum by (%(aggregationsIncludingComponent)s)(
        sum_over_time(
          gitlab:component:stage_group:execution:ops:rate_1h{%(selectors)s}[%(range)s]
        )
      ) %(ignoreCondition)s
    )
  ||| % partsInterpolation;
  |||
    ceil(
      (
        sum by (%(aggregationLabelsWithViolationType)s) (
          %(apdexOperationRate)s
          or
          %(errorOperationRate)s
        ) > 0
      ) * 60
    )
  ||| % {
    aggregationLabelsWithViolationType: aggregations.join(aggregationLabels),
    apdexOperationRate: strings.indent(labels.addStaticLabel('violation_type', 'apdex', apdexOperationRate), 6),
    errorOperationRate: strings.indent(labels.addStaticLabel('violation_type', 'error', errorOperationRate), 6),
  };


{
  init(slaTarget, range): {
    errorBudgetRatio(selectors, aggregationLabels=[], ignoreComponents=true):
      errorBudgetRatio(range, selectors, aggregationLabels, ignoreComponents),
    errorBudgetTimeSpent(selectors, aggregationLabels=[], ignoreComponents=true):
      errorBudgetTimeSpent(range, selectors, aggregationLabels, ignoreComponents),
    errorBudgetTimeRemaining(selectors, aggregationLabels=[], ignoreComponents=true):
      errorBudgetTimeRemaining(slaTarget, range, selectors, aggregationLabels, ignoreComponents),
    errorBudgetViolationRate(selectors, aggregationLabels=[], ignoreComponents=true):
      errorBudgetViolationRate(range, selectors, aggregationLabels, ignoreComponents),
    errorBudgetOperationRate(selectors, aggregationLabels=[], ignoreComponents=true):
      errorBudgetOperationRate(range, selectors, aggregationLabels, ignoreComponents),
  },
}
