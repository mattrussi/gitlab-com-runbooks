local rateMetric = (import 'servicemetrics/metrics.libsonnet').rateMetric;
local histogramApdex = (import 'servicemetrics/histogram_apdex.libsonnet').histogramApdex;

local metricsCatalog = import '../../metrics-catalog.libsonnet';

local aggregationLabels = [
  'environment',
  'tier',
  'type',
  'stage',
  'feature_category',
];

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
      satisfiedThreshold='%i.0' % [pumaComponent.apdex.satisfiedThreshold],
    )
  else null;

local latencyApdexRatioRules(selector, rangeInterval) =
  local apdex = latencyApdex(selector.type);
  if apdex != null then
    [
      {
        record: 'gitlab:component:feature_category:execution:apdex:ratio_%s' % [rangeInterval],
        labels: { component: 'puma' },
        expr: latencyApdex(selector.type).apdexQuery(aggregationLabels, selector, rangeInterval),
      },
      {
        record: 'gitlab:component:feature_category:execution:apdex:weight:score_%s' % [rangeInterval],
        labels: { component: 'puma' },
        expr: latencyApdex(selector.type).apdexWeightQuery(aggregationLabels, selector, rangeInterval),
      },
      {
        record: 'gitlab:component:feature_category:execution:apdex:success:rate_%s' % [rangeInterval],
        labels: { component: 'puma' },
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
          labels: { component: 'puma' },
          expr: requestRate.aggregatedRateQuery(aggregationLabels, selector, rangeInterval),
        },
        {
          record: 'gitlab:component:feature_category:execution:error:rate_%s' % [rangeInterval],
          labels: { component: 'puma' },
          expr: errorRate.aggregatedRateQuery(aggregationLabels, selector, rangeInterval),
        },
        {
          record: 'gitlab:component:feature_category:execution:error:ratio_%s' % [rangeInterval],
          expr: |||
            gitlab:component:feature_category:execution:error:rate_%(rangeInterval)s
            /
            gitlab:component:feature_category:execution:ops:rate_%(rangeInterval)s > 0
          ||| % { rangeInterval: rangeInterval },
        },
      ] + latencyApdexRatioRules(selector, rangeInterval),
}
