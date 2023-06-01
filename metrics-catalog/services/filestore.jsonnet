local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local toolingLinks = import 'toolinglinks/toolinglinks.libsonnet';
local gaugeMetric = metricsCatalog.gaugeMetric;

metricsCatalog.serviceDefinition({
  type: 'filestore',
  tier: 'stor',

  tags: ['filestore'],

  monitoringThresholds: {
    apdexScore: 0.995,
    errorRatio: 0.9999,
  },
  regional: false,

  provisioning: {
    vms: false,
    kubernetes: false,
  },

  serviceLevelIndicators: {},

  skippedMaturityCriteria: {
    'Structured logs available in Kibana': 'Filestore is a managed service of GCP. The logs are available in Stackdriver.',
    'Developer guides exist in developer documentation': 'Filestore is an infrastructure component, powered by GCP',
  },
})
