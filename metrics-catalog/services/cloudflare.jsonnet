local metricsCatalog = import 'servicemetrics/metrics.libsonnet';

metricsCatalog.serviceDefinition({
  type: 'cloudflare',
  tier: 'inf',
  tags: ['cloudflare'],
  serviceLevelIndicators: {},
})
