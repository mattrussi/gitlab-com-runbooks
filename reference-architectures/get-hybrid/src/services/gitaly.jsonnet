local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local rateMetric = metricsCatalog.rateMetric;
local gitalyHelper = import 'service-archetypes/helpers/gitaly.libsonnet';

metricsCatalog.serviceDefinition({
  type: 'gitaly',
  tier: 'stor',

  tags: ['golang'],

  nodeLevelMonitoring: false,
  monitoringThresholds: {
    apdexScore: 0.999,
    errorRatio: 0.9995,
  },
  serviceLevelIndicators: {
    goserver: {
      userImpacting: true,
      description: |||
        This SLI monitors all Gitaly GRPC requests in aggregate, excluding the OperationService.
        GRPC failures which are considered to be the "server's fault" are counted as errors.
        The apdex score is based on a subset of GRPC methods which are expected to be fast.
      |||,

      local baseSelector = {
        job: 'gitaly',
        grpc_service: { ne: 'gitaly.OperationService' },
      },

      local baseSelectorApdex = baseSelector {
        grpc_method: { noneOf: gitalyHelper.gitalyApdexIgnoredMethods },
      },

      apdex: gitalyHelper.grpcServiceApdex(baseSelectorApdex),

      requestRate: rateMetric(
        counter='gitaly_service_client_requests_total',
        selector=baseSelector
      ),

      errorRate: gitalyHelper.gitalyGRPCErrorRate(baseSelector),

      significantLabels: ['node'],

      toolingLinks: [],
    },
  },
})
