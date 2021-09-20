local metricsCatalog = import 'servicemetrics/metrics.libsonnet';

metricsCatalog.serviceDefinition({
  type: 'consul',
  tier: 'sv',
  monitoringThresholds: {
  },
  serviceDependencies: {
  },
  provisioning: {
    vms: true,
    kubernetes: true,
  },
  regional: true,
  kubeResources: {
    consul: {
      kind: 'Daemonset',
      containers: [
        'consul',
      ],
    },
  },
  serviceLevelIndicators: {
  },
})
