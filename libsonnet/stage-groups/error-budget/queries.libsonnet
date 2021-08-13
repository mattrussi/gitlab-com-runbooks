local utils = import './utils.libsonnet';
local aggregations = import 'promql/aggregations.libsonnet';
local labels = import 'promql/labels.libsonnet';
local selectors = import 'promql/selectors.libsonnet';
local durationParser = import 'utils/duration-parser.libsonnet';
local strings = import 'utils/strings.libsonnet';

local errorBudgetRatio(slaTarget, range, groupSelectors, aggregationLabels) =
  |||
    # Account for missing metrics that are turned into 0 by `vector(0)`.
    clamp_max(
      # Number of successful measurements
      sum by (%(aggregations)s)(
        # Reuest with satisfactory apdex
        label_replace(
          sum_over_time(
            gitlab:component:stage_group:execution:apdex:success:rate_1h{%(selectorHash)s}[%(range)s]
          ), 'sli_kind', 'apdex', '', '')
        or
        # Requests without error
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
          ), 'sli_kind', 'error', '', '')
      )
      /
      # Number of measurements
      sum by (%(aggregations)s)(
        # Apdex Measurements
        label_replace(
          sum_over_time(
            gitlab:component:stage_group:execution:apdex:weight:score_1h{%(selectorHash)s}[%(range)s]
          ),
        'sli_kind', 'apdex', '', '')
        or
        # Requests
        label_replace(
          sum_over_time(
            gitlab:component:stage_group:execution:ops:rate_1h{%(selectorHash)s}[%(range)s]
          ),
        'sli_kind', 'error', '', '')
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

local errorBudgetViolationRate(range, groupSelectors, aggregationLabels) =
  local partsInterpolation = {
    aggregationLabels: aggregations.join(
      std.filter(
        function(label) label != 'violation_type',
        aggregationLabels
      )
    ),
    selectors: selectors.serializeHash(groupSelectors),
    range: range,
  };
  local apdexViolationRate = |||
    sum by (%(aggregationLabels)s)(
      sum_over_time(
        gitlab:component:stage_group:execution:apdex:weight:score_1h{%(selectors)s}[%(range)s]
      ) -
      # Request with satisfactory apdex
      sum_over_time(
        gitlab:component:stage_group:execution:apdex:success:rate_1h{%(selectors)s}[%(range)s]
      )
    )
  ||| % partsInterpolation;
  local errorRate = |||
    sum by (%(aggregationLabels)s)(
      sum_over_time(
        gitlab:component:stage_group:execution:error:rate_1h{%(selectors)s}[%(range)s]
      )
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

{
  init(slaTarget, range): {
    errorBudgetRatio(selectors, aggregationLabels=[]):
      errorBudgetRatio(slaTarget, range, selectors, aggregationLabels),
    errorBudgetTimeSpent(selectors, aggregationLabels=[]):
      errorBudgetTimeSpent(slaTarget, range, selectors, aggregationLabels),
    errorBudgetTimeRemaining(selectors, aggregationLabels=[]):
      errorBudgetTimeRemaining(slaTarget, range, selectors, aggregationLabels),
    errorBudgetViolationRate(selectors, aggregationLabels=[]):
      errorBudgetViolationRate(range, selectors, aggregationLabels),
  },
}
