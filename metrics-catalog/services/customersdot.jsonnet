local sliLibrary = import 'gitlab-slis/library.libsonnet';
local maturityLevels = import 'service-maturity/levels.libsonnet';
local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local toolingLinks = import 'toolinglinks/toolinglinks.libsonnet';

metricsCatalog.serviceDefinition({
  type: 'customersdot',
  tier: 'sv',

  monitoringThresholds: {
    apdexScore: 0.95,
    errorRatio: 0.998,
  },

  serviceDependencies: {
    api: true,
  },

  provisioning: {
    vms: true,
    kubernetes: false,
  },

  regional: false,

  serviceLevelIndicators: {
    rails_requests:
      sliLibrary.get('customers_dot_requests').generateServiceLevelIndicator(extraSelector={}) {
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
      },
  },
  skippedMaturityCriteria: maturityLevels.skip({
    'Structured logs available in Kibana': 'All logs are available in Stackdriver',
  }),
})
