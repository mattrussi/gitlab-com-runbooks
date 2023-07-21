local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local rateMetric = metricsCatalog.rateMetric;
local toolingLinks = import 'toolinglinks/toolinglinks.libsonnet';
local kubeLabelSelectors = metricsCatalog.kubeLabelSelectors;

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
  kubeConfig: {
    labelSelectors: kubeLabelSelectors(
      ingressSelector=null  // no ingress for logging
    ),
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
      local queueSelector = { worker: 'EmailReceiverWorker' },
      userImpacting: true,
      featureCategory: 'not_owned',

      // Avoid long burn rates on Sidekiq metrics...
      upscaleLongerBurnRates: true,

      description: |||
        Monitors incoming emails delivered from the imap inbox and processed through Sidekiq's `EmailReceiverWorker`.
        Note that since Mailroom has poor observability, we use Sidekiq metrics for this, and this could lead to certain Sidekiq problems
        being attributed to Mailroom
      |||,

      requestRate: rateMetric(
        counter='gitlab_sli_sidekiq_execution_apdex_total',
        selector=queueSelector,
      ),

      errorRate: rateMetric(
        counter='gitlab_sli_sidekiq_execution_error_total',
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
