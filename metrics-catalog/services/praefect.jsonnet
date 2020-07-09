local metricsCatalog = import '../lib/metrics.libsonnet';
local rateMetric = metricsCatalog.rateMetric;
local gitalyHelpers = import './lib/gitaly-helpers.libsonnet';

{
  type: 'praefect',
  tier: 'stor',
  deprecatedSingleBurnThresholds: {
    apdexRatio: 0.995,
    errorRatio: 0.0005,
  },
  monitoringThresholds: {
    apdexScore: 0.995,
    errorRatio: 0.9995,  // 99.95% of Praefect requests should succeed, over multiple window periods
  },
  serviceDependencies: {
    gitaly: true,
  },
  components: {
    proxy: {
      local baseSelector = { job: 'praefect' },
      apdex: gitalyHelpers.grpcServiceApdex(baseSelector),

      requestRate: rateMetric(
        counter='grpc_server_handled_total',
        selector=baseSelector
      ),

      errorRate: rateMetric(
        counter='grpc_server_handled_total',
        selector=baseSelector {
          grpc_code: { nre: '^(OK|NotFound|Unauthenticated|AlreadyExists|FailedPrecondition)$' },
        }
      ),

      significantLabels: ['fqdn'],
    },
  },
}
