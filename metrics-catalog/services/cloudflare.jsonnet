local metricsCatalog = import 'servicemetrics/metrics.libsonnet';

metricsCatalog.serviceDefinition({
  type: 'cloudflare',
  tier: 'inf',
  tenants: ['metamonitoring'],
  tags: ['cloudflare'],
  serviceLevelIndicators: {},
})
