local rateMetric = (import 'servicemetrics/metrics.libsonnet').rateMetric;
local histogramApdex = (import 'servicemetrics/histogram_apdex.libsonnet').histogramApdex;
local aggregations = import 'promql/aggregations.libsonnet';
local metricsCatalog = import 'servicemetrics/metrics-catalog.libsonnet';
local selectors = import 'promql/selectors.libsonnet';
local strings = import 'utils/strings.libsonnet';
local aggregationSets = import 'aggregation-sets.libsonnet';
local aggregationSet = aggregationSets.featureCategorySourceSLIs;

local aggregationLabels = aggregationSet.labels;
local staticLabels = { component: 'puma' };

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
      labels: staticLabels,
      expr: latencyApdex.apdexWeightQuery(aggregationLabels, {}, rangeInterval),
    },
    {
      record: aggregationSet.getApdexSuccessRateMetricForBurnRate(rangeInterval),
      labels: staticLabels,
      expr: latencyApdex.apdexSuccessRateQuery(aggregationLabels, {}, rangeInterval),
    },
  ];

{
  // Record error rates for each category
  perFeatureCategoryRecordingRules::
    std.flatMap(
      function(rangeInterval)
        [
          {
            record: aggregationSet.getOpsRateMetricForBurnRate(rangeInterval),
            labels: staticLabels,
            expr: requestRate.aggregatedRateQuery(aggregationLabels, {}, rangeInterval),
          },
          {
            record: aggregationSet.getErrorRateMetricForBurnRate(rangeInterval),
            labels: staticLabels,
            expr: |||
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
        ] + latencyApdexRateRules(rangeInterval),
      aggregationSet.getBurnRates()
    ),
}
