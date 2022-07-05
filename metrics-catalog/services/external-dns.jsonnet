local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local rateMetric = metricsCatalog.rateMetric;

metricsCatalog.serviceDefinition({
  type: 'external-dns',
  tier: 'sv',
  provisioning: {
    vms: false,
    kubernetes: true,
  },
  serviceLevelIndicators: {},
})
