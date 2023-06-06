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

  // This is evaluated in Thanos because the prometheus uses thanos-receive to
  // get its metrics available.
  // Our recording rules are currently not deployed to the external cluster that runs
  // code-suggestions.
  // We should get rid of this to be in line with other services when we can
  dangerouslyThanosEvaluated: true,

  serviceLevelIndicators: {},

  skippedMaturityCriteria: {
    'Structured logs available in Kibana': 'Filestore is a managed service of GCP. The logs are available in Stackdriver.',
    'Developer guides exist in developer documentation': 'Filestore is an infrastructure component, powered by GCP',
  },
})
