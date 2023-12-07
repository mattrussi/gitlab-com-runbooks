local metricsCatalog = import 'servicemetrics/metrics.libsonnet';

metricsCatalog.serviceDefinition({
  type: 'runtime-scan',
  tier: 'inf',

  tags: ['wiz-sensor'],

  serviceIsStageless: true,

  monitoringThresholds: {
    apdexScore: 0.999,
    errorRatio: 0.999,
  },

  provisioning: {
    kubernetes: true,
    vms: false,
  },

  kubeResources: {
    'wiz-sensor': {
      kind: 'daemonset',
      containers: [
        'wiz-sensor',
      ],
    },
  },

  serviceLevelIndicators: {
  },

  skippedMaturityCriteria: {
  },
})
