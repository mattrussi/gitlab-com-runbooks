local sliLibrary = import 'gitlab-slis/library.libsonnet';
local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local toolingLinks = import 'toolinglinks/toolinglinks.libsonnet';
local rateMetric = metricsCatalog.rateMetric;

metricsCatalog.serviceDefinition({
  type: 'customersdot',
  tier: 'sv',

  monitoringThresholds: {
    apdexScore: 0.993,
    errorRatio: 0.95,
  },

  serviceDependencies: {
    api: true,
  },

  provisioning: {
    vms: true,
    kubernetes: false,
  },

  regional: false,

  serviceLevelIndicators:
    sliLibrary.get('customers_dot_requests').generateServiceLevelIndicator({}, {
      severity: 's2',
      toolingLinks: [
        toolingLinks.kibana(title='CustomersDot Requests', index='customers_dot_requests'),
      ],
    })
    +
    sliLibrary.get('customers_dot_sidekiq_jobs').generateServiceLevelIndicator({ type: 'customersdot' }, {
      severity: 's3',
      toolingLinks: [
        toolingLinks.kibana(title='CustomersDot Sidekiq', index='customers_dot_sidekiq'),
      ],
    }),
})
