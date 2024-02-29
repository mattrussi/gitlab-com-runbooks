local metricsCatalog = import 'servicemetrics/metrics.libsonnet';

// This is a mock service definition to deal with some utilization metrics that we use for cloudflare

metricsCatalog.serviceDefinition({
  type: 'cloudflare',
  tier: 'inf',
  tags: ['cloudflare'],
  serviceLevelIndicators: {},
  skippedMaturityCriteria: {
    'Structured logs available in Kibana': 'This is a mock service definition to deal with cloudflare utilization metrics',
    'Service exists in the dependency graph': 'This is a mock service definition to deal with cloudflare utilization metrics',
    'Developer guides exist in developer documentation': 'This is a mock service defnition to deal with cloudflare utilization metrics',
  },
})
