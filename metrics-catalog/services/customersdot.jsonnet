local sliLibrary = import 'gitlab-slis/library.libsonnet';
local maturityLevels = import 'service-maturity/levels.libsonnet';
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

    sidekiq_jobs: {
      local baseSelector = {
        type: 'customersdot',
      },

      description: |||
        This SLI monitors all Sidekiq jobs requests triggered in CustomersDot.
        We're displaying the aggregation by endpoint and feature category of
        the total number of processed request and of all the failed requests.
      |||,

      requestRate: rateMetric(
        counter='sidekiq_processed_jobs_total',
        selector=baseSelector
      ),

      errorRate: rateMetric(
        counter='sidekiq_failed_jobs_total',
        selector=baseSelector
      ),

      userImpacting: true,
      severity: 's3',
      serviceAggregation: false,
      featureCategory: 'fulfillment_platform',
      significantLabels: ['feature_category', 'endpoint_id'],
    },
  },
  skippedMaturityCriteria: maturityLevels.skip({
    'Structured logs available in Kibana': 'All logs are available in Stackdriver',
  }),
})
