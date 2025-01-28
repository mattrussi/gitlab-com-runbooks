local metricsCatalog = import 'servicemetrics/metrics.libsonnet';

function(
  type,
  descriptiveName,
  featureCategory='not_owned',
  regional=false
) {
  type: type,
  tier: 'db',
  tenants: ['runway'],
  tags: [],  // TODO: add 'cloud-sql' for capacity planning

  monitoringThresholds: {
    apdexScore: 0.999,
    errorRatio: 0.999,
  },

  regional: regional,

  provisioning: {
    runway: true,
    vms: false,
    kubernetes: false,
  },

  serviceIsStageless: true,

  serviceLevelIndicators: {
    // TODO: add default SLIs
  },

  skippedMaturityCriteria: {
    'Structured logs available in Kibana': 'Runway structured logs are temporarily available in Stackdriver',
    'Service exists in the dependency graph': 'No service currently depends on Postgres database, which is under development',
  },
}
