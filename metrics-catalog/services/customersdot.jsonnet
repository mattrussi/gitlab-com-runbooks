local metricsCatalog = import 'servicemetrics/metrics.libsonnet';

metricsCatalog.serviceDefinition({
  type: 'customersdot',
  tier: 'sv',

  monitoringThresholds: {
    apdexScore: 0.92,
    errorRatio: 0.998,
  },

  recordingRuleMetrics: sliLibrary.get('customers_dot_requests_apdex').recordingRuleMetrics,

  provisioning: {
    vms: true,
    kubernetes: false,
  },

  regional: false,

  serviceLevelIndicators: {
    rails_requests:
      sliLibrary.get('customers_dot_requests_apdex').generateServiceLevelIndicator(railsSelector) {
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
