local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local rateMetric = metricsCatalog.rateMetric;

metricsCatalog.serviceDefinition({
  type: 'google_cloud_storage',
  tier: 'sv',
  monitoringThresholds: {
    apdexScore: 0.997,
    errorRatio: 0.9999,
  },
  regional: true,
  serviceLevelIndicators: {
    registry_storage: {
      userImpacting: true,
      featureCategory: 'container_registry',
      description: |||
        Aggregation of all container registry GCS storage operations.
      |||,

      apdex: histogramApdex(
        histogram='registry_storage_action_seconds_bucket',
        selector='',
        satisfiedThreshold=1
      ),

      requestRate: rateMetric(
        counter='registry_storage_action_seconds_count',
      ),

      significantLabels: ['action', 'migration_path'],
    },
  },
})