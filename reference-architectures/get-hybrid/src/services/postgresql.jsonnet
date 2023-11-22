local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local toolingLinks = import 'toolinglinks/toolinglinks.libsonnet';
local kubeLabelSelectors = metricsCatalog.kubeLabelSelectors;

metricsCatalog.serviceDefinition({
  type: 'postgresql',
  tier: 'db',
  provisioning: {
    vms: false,
    kubernetes: false,
  },
  serviceLevelIndicators: {
    // No SLIs for now
  },
})
