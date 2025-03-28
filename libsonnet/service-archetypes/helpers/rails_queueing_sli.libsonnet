local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local rateMetric = metricsCatalog.rateMetric;

function(satisfiedThreshold, toleratedThreshold, selector={})
  {
    rails_queueing: {
      userImpacting: true,
      serviceAggregation: false,  // The requests are already counted in the `puma/rails_request` SLI.
      description: |||
        Apdex for time spent waiting for a Puma worker
      |||,

      requestRate: rateMetric(
        counter='gitlab_rails_queue_duration_seconds_count',
        selector=selector,
      ),

      apdex: histogramApdex(
        histogram='gitlab_rails_queue_duration_seconds_bucket',
        selector=selector,
        satisfiedThreshold=satisfiedThreshold,
        toleratedThreshold=toleratedThreshold
      ),

      significantLabels: [],
    },
  }
