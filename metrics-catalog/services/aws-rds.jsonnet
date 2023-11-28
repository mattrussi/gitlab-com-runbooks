local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local toolingLinks = import 'toolinglinks/toolinglinks.libsonnet';
local gaugeMetric = metricsCatalog.gaugeMetric;

metricsCatalog.serviceDefinition({
  type: 'rds',
  tier: 'db',

  tags: ['rds'],

  monitoringThresholds: {
    apdexScore: 0.995,
    errorRatio: 0.9999,
  },
  regional: true,

  provisioning: {
    vms: false,
    kubernetes: false,
  },

  serviceLevelIndicators: {},

  skippedMaturityCriteria: {},
})