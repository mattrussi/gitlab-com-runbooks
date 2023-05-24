local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local rateMetric = metricsCatalog.rateMetric;
local toolingLinks = import 'toolinglinks/toolinglinks.libsonnet';

local baseSelector = { type: 'code_suggestions' };

metricsCatalog.serviceDefinition({
  type: 'code_suggestions',
  tier: 'sv',
  monitoringThresholds: {
    apdexScore: 0.999,
    errorRatio: 0.999,
  },
  provisioning: {
    vms: false,
    kubernetes: true,
  },
  serviceDependencies: {
    api: true,
  },
  serviceIsStageless: true,

  // This is evaluated in Thanos because the prometheus uses thanos-receive to
  // get its metrics available.
  // Our recording rules are currently not deployed to the external cluster that runs
  // code-suggestions.
  // We should get rid of this to be in line with other services when we can
  dangerouslyThanosEvaluated: true,

  serviceLevelIndicators: {
    server: {
      severity: 's3',  // NOTE: Do not page on-call SREs until production ready
      userImpacting: true,
      team: 'ai_assisted',
      featureCategory: 'code_suggestions',

      requestRate: rateMetric(
        counter='http_requests_total',
        selector=baseSelector,
        useRecordingRuleRegistry=false,
      ),

      errorRate: rateMetric(
        counter='http_requests_total',
        selector=baseSelector { status: { re: '^5.*' } },
        useRecordingRuleRegistry=false,
      ),

      significantLabels: ['status'],

      toolingLinks: [
        toolingLinks.kibana(title='MLOps', index='mlops'),
      ],
    },
  },
})
