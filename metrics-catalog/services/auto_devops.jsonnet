local metricsCatalog = import '../lib/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local rateMetric = metricsCatalog.rateMetric;
local customQuery = metricsCatalog.customQuery;

{
  type: 'auto_devops',
  tier: 'sv',
  slos: {
    apdexRatio: 1.0,
    errorRatio: 1.0,
  },
  components: {
    completed_pipelines: {
      requestRate: rateMetric(
        counter='auto_devops_pipelines_completed_total',
        selector=''
      ),

      errorRate: rateMetric(
        counter='auto_devops_pipelines_completed_total',
        selector='status=~"failed"'
      ),
    },
  },
}
