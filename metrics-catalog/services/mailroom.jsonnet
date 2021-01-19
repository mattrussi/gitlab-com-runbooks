local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local rateMetric = metricsCatalog.rateMetric;

metricsCatalog.serviceDefinition({
  type: 'mailroom',
  tier: 'sv',
  monitoringThresholds: {
    errorRatio: 0.9995,
  },
  serviceDependencies: {
    patroni: true,
    pgbouncer: true,
  },
  provisioning: {
    kubernetes: true,
    vms: false,
  },
  kubeResources: {
    mailroom: {
      kind: 'Deployment',
      containers: [
        'mailroom',
      ],
    },
  },
  serviceLevelIndicators: {
    emailsProcessed: {
      local queueSelector = { queue: 'email_receiver' },
      userImpacting: true,
      featureCategory: 'not_owned',
      team: 'sre_coreinfra',
      description: |||
        Monitors incoming emails delivered from the imap inbox and processed through Sidekiq's `email_receiver` queue.
        Note that since Mailroom has poor observability, we use Sidekiq metrics for this, and this could lead to certain Sidekiq problems
        being attributed to Mailroom
      |||,

      staticLabels: {
        // Since we take this metric from other services
        // which do have the correct `stage` label, we need to
        // hardcode it here
        stage: 'main',
      },

      requestRate: rateMetric(
        counter='sidekiq_jobs_completion_seconds_bucket',  // Use the histogram bucket allows us to use Sidekiq's intermediate SLI recording rules here
        selector=queueSelector { le: '+Inf' },
      ),

      errorRate: rateMetric(
        counter='sidekiq_jobs_failed_total',
        selector=queueSelector,
      ),

      significantLabels: [],
    },
  },
})
