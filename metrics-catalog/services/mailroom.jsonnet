local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local rateMetric = metricsCatalog.rateMetric;
local toolingLinks = import 'toolinglinks/toolinglinks.libsonnet';

metricsCatalog.serviceDefinition({
  type: 'mailroom',
  tier: 'sv',
  serviceIsStageless: true,  // mailroom does not have a cny stage
  monitoringThresholds: {
    errorRatio: 0.9995,
  },
  serviceDependencies: {
    patroni: true,
    pgbouncer: true,
    consul: true,
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

      // Avoid long burn rates on Sidekiq metrics...
      upscaleLongerBurnRates: true,

      description: |||
        Monitors incoming emails delivered from the imap inbox and processed through Sidekiq's `email_receiver` queue.
        Note that since Mailroom has poor observability, we use Sidekiq metrics for this, and this could lead to certain Sidekiq problems
        being attributed to Mailroom
      |||,

      requestRate: rateMetric(
        counter='sidekiq_jobs_completion_seconds_bucket',  // Use the histogram bucket allows us to use Sidekiq's intermediate SLI recording rules here
        selector=queueSelector { le: '+Inf' },
      ),

      errorRate: rateMetric(
        counter='sidekiq_jobs_failed_total',
        selector=queueSelector,
      ),

      significantLabels: [],

      toolingLinks: [
        toolingLinks.kibana(title='Mailroom', index='mailroom', includeMatchersForPrometheusSelector=false),
        toolingLinks.kibana(
          title='Sidekiq receiver workers',
          index='sidekiq',
          includeMatchersForPrometheusSelector=false,
          matches={ 'json.class': ['EmailReceiverWorker', 'ServiceDeskEmailReceiverWorker'] }
        ),
      ],
    },
  },
})
