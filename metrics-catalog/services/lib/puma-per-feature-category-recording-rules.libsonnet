local rateMetric = (import 'servicemetrics/metrics.libsonnet').rateMetric;
local histogramApdex = (import 'servicemetrics/histogram_apdex.libsonnet').histogramApdex;

local aggregations = import 'promql/aggregations.libsonnet';
local metricsCatalog = import '../../metrics-catalog.libsonnet';
local selectors = import 'promql/selectors.libsonnet';
local strings = import 'utils/strings.libsonnet';

local aggregationLabels = [
  'environment',
  'tier',
  'type',
  'stage',
  'feature_category',
];

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

local latencyApdex(service) =
  local pumaComponent = metricsCatalog.getService(service).serviceLevelIndicators.puma;
  if std.objectHas(pumaComponent, 'apdex') then
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
    )
  else null;

local latencyApdexRatioRules(selector, rangeInterval) =
  local apdex = latencyApdex(selector.type);
  if apdex != null then
    [
      {
        record: 'gitlab:component:feature_category:execution:apdex:weight:score_%s' % [rangeInterval],
        labels: staticLabels,
        expr: latencyApdex(selector.type).apdexWeightQuery(aggregationLabels, selector, rangeInterval),
      },
      {
        record: 'gitlab:component:feature_category:execution:apdex:success:rate_%s' % [rangeInterval],
        labels: staticLabels,
        expr: latencyApdex(selector.type).apdexSuccessRateQuery(aggregationLabels, selector, rangeInterval),
      },
    ]
  else
    [];

{
  // Record error rates for each category
  perFeatureCategoryRecordingRules(selector)::
    function(rangeInterval)
      [
        {
          record: 'gitlab:component:feature_category:execution:ops:rate_%s' % [rangeInterval],
          labels: staticLabels,
          expr: requestRate.aggregatedRateQuery(aggregationLabels, selector, rangeInterval),
        },
        {
          record: 'gitlab:component:feature_category:execution:error:rate_%s' % [rangeInterval],
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
            errorRate: strings.chomp(errorRate.aggregatedRateQuery(aggregationLabels, selector, rangeInterval)),
            rangeInterval: rangeInterval,
            aggregationLabels: aggregations.serialize(aggregationLabels),
            operationRateName: 'gitlab:component:feature_category:execution:ops:rate_%s' % [rangeInterval],
            staticLabels: selectors.serializeHash(selector + staticLabels),
          },
        },
      ] + latencyApdexRatioRules(selector, rangeInterval),
}
