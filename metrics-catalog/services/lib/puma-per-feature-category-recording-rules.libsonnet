local rateMetric = (import 'servicemetrics/metrics.libsonnet').rateMetric;

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
      ],
}
