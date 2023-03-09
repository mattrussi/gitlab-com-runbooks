local sliLibrary = import 'gitlab-slis/library.libsonnet';
local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local toolingLinks = import 'toolinglinks/toolinglinks.libsonnet';
local rateMetric = metricsCatalog.rateMetric;

metricsCatalog.serviceDefinition({
  type: 'customersdot',
  tier: 'sv',

  monitoringThresholds: {
    apdexScore: 0.9,
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
      severity: 's3',
      toolingLinks: [
        toolingLinks.stackdriverLogs(
          'Stackdriver Logs: CustomersDot',
          queryHash={
            'resource.type': 'gce_instance',
            'jsonPayload.controller': { exists: true },
            'jsonPayload.duration': { exists: true },
          },
          project='gitlab-subscriptions-prod',
        ),
      ],
    })
    +
    sliLibrary.get('customers_dot_sidekiq_jobs').generateServiceLevelIndicator({ type: 'customersdot' }, {
      severity: 's3',
    }),
  skippedMaturityCriteria: {
    'Structured logs available in Kibana': 'All logs are available in Stackdriver',
  },
})
