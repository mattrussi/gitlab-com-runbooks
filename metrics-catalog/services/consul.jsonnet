local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local toolingLinks = import 'toolinglinks/toolinglinks.libsonnet';

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
    consul: {
      userImpacting: false,
      featureCategory: 'not_owned',
      description: |||
        HTTP GET requests handled by the Consul agent.
      |||,

      requestRate: metricsCatalog.derivMetric(
        counter='consul_http_GET_v1_agent_metrics_count',
        clampMinZero=true,
      ),

      significantLabels: ['type'],

      toolingLinks: [
        toolingLinks.kibana(title='Consul', index='consul', includeMatchersForPrometheusSelector=false),
      ],
    },
  },
})
