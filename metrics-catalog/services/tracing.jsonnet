local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local toolingLinks = import 'toolinglinks/toolinglinks.libsonnet';

metricsCatalog.serviceDefinition({
  type: 'tracing',
  tier: 'sv',
  serviceDependencies: {
    api: true,
  },
  provisioning: {
    kubernetes: false,
    vms: false,
  },
  serviceLevelIndicators: {},
})
