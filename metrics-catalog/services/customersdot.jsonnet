local sliLibrary = import 'gitlab-slis/library.libsonnet';
local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local toolingLinks = import 'toolinglinks/toolinglinks.libsonnet';

metricsCatalog.serviceDefinition({
  type: 'customersdot',
  tier: 'sv',

  monitoringThresholds: {
    apdexScore: 0.92,
    errorRatio: 0.998,
  },

  provisioning: {
    vms: true,
    kubernetes: false,
  },

  regional: false,

  serviceLevelIndicators: {
    rails_requests:
      sliLibrary.get('customers_dot_requests_apdex').generateServiceLevelIndicator(extraSelector={}) {
        toolingLinks: [
          toolingLinks.stackdriverLogs(
            'Stackdriver Logs: CustomersDot',
            queryHash={
              'resource.type': 'gce_instance',
              'jsonPayload.duration': '*',
            },
          ),
        ],
      },
  },
})
