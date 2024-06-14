local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local rateMetric = metricsCatalog.rateMetric;

metricsCatalog.serviceDefinition({
  type: 'zoekt',
  tier: 'inf',
  monitoringThresholds: {
    apdexScore: 0.999,
    errorRatio: 0.999,
  },
  provisioning: {
    kubernetes: true,
    vms: false,
  },
  kubeResources: {
    'gitlab-zoekt': {
      kind: 'StatefulSet',
      containers: [
        'zoekt-indexer',
        'zoekt-webserver',
        'zoekt-internal-gateway',
      ],
    },
    'gitlab-zoekt-gateway': {
      kind: 'Deployment',
      containers: [
        'zoekt-external-gateway',
      ],
    },
  },
  serviceLevelIndicators: {},
  skippedMaturityCriteria: {
    'Structured logs available in Kibana': 'logs are available at https://log.gprd.gitlab.net/app/r/s/U9Av8, but not linked to SLIs as there are no SLIs for now.',
  },
})
