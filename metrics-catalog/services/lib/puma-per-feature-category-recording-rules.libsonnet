local rateMetric = (import 'servicemetrics/metrics.libsonnet').rateMetric;
local histogramApdex = (import 'servicemetrics/histogram_apdex.libsonnet').histogramApdex;
local aggregations = import 'promql/aggregations.libsonnet';
local metricsCatalog = import 'servicemetrics/metrics-catalog.libsonnet';
local selectors = import 'promql/selectors.libsonnet';
local strings = import 'utils/strings.libsonnet';
local aggregationSets = import 'aggregation-sets.libsonnet';
local aggregationSet = aggregationSets.featureCategorySourceSLIs;
local recordingRuleHelpers = import 'recording-rules/helpers.libsonnet';
local upscaleLabels = (import 'servicemetrics/service_level_indicator_definition.libsonnet').upscaleLabels;

local staticLabels = { component: 'puma' };
local aggregationLabels = std.filter(
  function(label)
    !std.objectHas(staticLabels, label),
  aggregationSet.labels
);

local staticLabelsForBurnRate(burnRate) = if aggregationSet.upscaleBurnRate(burnRate) && burnRate == '1h' then
  upscaleLabels + staticLabels
else staticLabels;

local requestRate = rateMetric(
  counter='http_requests_total',
  selector={
    job: 'gitlab-rails',
  },
);

local errorRate = rateMetric(
  counter='http_requests_total',
  selector={
    job: 'gitlab-rails',
    status: { re: '5..' },
  },
);

local latencyApdex =
  histogramApdex(
    histogram='gitlab_transaction_duration_seconds_bucket',
    selector={ job: 'gitlab-rails' },
    // The threshold that is used for error budgets is different from the alerting
    // Please see https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/1243
    // We'll get this back to acceptable durations by introducing improved SLIs in
    // https://gitlab.com/groups/gitlab-com/gl-infra/-/epics/525
    // We're discussing applying the same SLO for error budgets in
    // https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/1232
    satisfiedThreshold='5.0'
  );

local latencyApdexRateRules(rangeInterval) =
  [
    {
      record: aggregationSet.getApdexWeightMetricForBurnRate(rangeInterval),
      labels: staticLabelsForBurnRate(rangeInterval),
      expr: if aggregationSet.upscaleBurnRate(rangeInterval) then
        recordingRuleHelpers.combinedApdexWeightExpression(aggregationSet, aggregationSet, rangeInterval, null, staticLabels + upscaleLabels)
      else latencyApdex.apdexWeightQuery(aggregationLabels, {}, rangeInterval),
    },
    {
      record: aggregationSet.getApdexSuccessRateMetricForBurnRate(rangeInterval),
      labels: staticLabelsForBurnRate(rangeInterval),
      expr: if aggregationSet.upscaleBurnRate(rangeInterval) then
        recordingRuleHelpers.combinedApdexSuccessRateExpression(aggregationSet, aggregationSet, rangeInterval, null, staticLabels + upscaleLabels)
      else latencyApdex.apdexSuccessRateQuery(aggregationLabels, {}, rangeInterval),
    },
  ];

local errorRateRules(rangeInterval) =
  [
    {
      record: aggregationSet.getOpsRateMetricForBurnRate(rangeInterval),
      labels: staticLabels,
      expr: if aggregationSet.upscaleBurnRate(rangeInterval) then
        recordingRuleHelpers.combinedOpsRateExpression(aggregationSet, aggregationSet, rangeInterval, null, staticLabels + upscaleLabels)
      else requestRate.aggregatedRateQuery(aggregationLabels, {}, rangeInterval),
    },
    {
      record: aggregationSet.getErrorRateMetricForBurnRate(rangeInterval),
      labels: staticLabels,
      expr: if aggregationSet.upscaleBurnRate(rangeInterval) then
        recordingRuleHelpers.combinedErrorRateExpression(aggregationSet, aggregationSet, rangeInterval, null, staticLabels + upscaleLabels)
      else
        |||
          %(errorRate)s
          or
          (
            0 * group by (%(aggregationLabels)s) (
              %(operationRateName)s{%(staticLabels)s}
            )
          )
        ||| % {
          errorRate: strings.chomp(errorRate.aggregatedRateQuery(aggregationLabels, {}, rangeInterval)),
          rangeInterval: rangeInterval,
          aggregationLabels: aggregations.serialize(aggregationLabels),
          operationRateName: aggregationSet.getOpsRateMetricForBurnRate(rangeInterval),
          staticLabels: selectors.serializeHash(staticLabels),
        },
    },
  ];

{
  // Record error rates for each category
  perFeatureCategoryRecordingRules::
    std.flatMap(
      function(rangeInterval)
        errorRateRules(rangeInterval) + latencyApdexRateRules(rangeInterval),
      aggregationSet.getBurnRates()
    ),
}
