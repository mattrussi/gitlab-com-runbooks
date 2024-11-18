local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local rateMetric = metricsCatalog.rateMetric;
local toolingLinks = import 'toolinglinks/toolinglinks.libsonnet';

metricsCatalog.serviceDefinition({
  type: 'http-router',
  tier: 'lb',
  // Metrics are collected in ops and relabelled with `env` and `environment`
  // based on their intended environment pairing.
  tenants: ['gitlab-ops'],
  tenantEnvironmentTargets: ['gprd', 'gstg'],

  monitoringThresholds: {
    errorRatio: 0.999,
  },
  serviceDependencies: {
    frontend: true,
    nat: true,
  },
  provisioning: {
    kubernetes: false,
    vms: false,
  },
  serviceIsStageless: true,

  tags: ['cloudflare-worker'],

  serviceLevelIndicators: {
    worker_requests: {
      severity: 's3',
      team: 'cells_infrastructure',
      // TODO: enable `userImpacting` when we've validated thresholds for alerting.
      userImpacting: false,
      featureCategory: 'not_owned',
      description: |||
        Aggregation of request that are flowing through the `http-router`.

        Errors on this SLI may indicate issues within the deployed `http-router`
        codebase as errors are limited to those originating inside of the worker.

        See: https://gitlab.com/gitlab-com/runbooks/-/blob/master/docs/http-router/logging.md?ref_type=heads
      |||,

      requestRate: rateMetric(
        counter='cloudflare_worker_requests_count',
      ),
      errorRate: rateMetric(
        counter='cloudflare_worker_errors_count',
      ),

      significantLabels: ['script_name'],

      toolingLinks: std.flattenArrays([
        [
          toolingLinks.cloudflareWorker.logs.live(scriptName='%s-gitlab-com-cells-http-router' % environment),
          toolingLinks.cloudflareWorker.logs.historical(scriptName='%s-gitlab-com-cells-http-router' % environment),
        ]
        for environment in [
          'production',
          'staging',
        ]
      ]),
    },
  },
  skippedMaturityCriteria: {
    'Structured logs available in Kibana': 'Logs from CloudFlare workers are stored and accessible in CloudFlare through the UI. See https://developers.cloudflare.com/workers/observability/logs/workers-logs/',
  },
})
