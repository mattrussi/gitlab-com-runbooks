local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local combined = metricsCatalog.combined;
local rateMetric = metricsCatalog.rateMetric;
local gitalyHelper = import 'service-archetypes/helpers/gitaly.libsonnet';
local toolingLinks = import 'toolinglinks/toolinglinks.libsonnet';

local baseSelector = { type: 'gitaly', job: 'gitaly' };

metricsCatalog.serviceDefinition({
  type: 'gitaly',
  tier: 'stor',

  // disk_performance_monitoring requires disk utilisation metrics are currently reporting correctly for
  // HDD volumes, see https://gitlab.com/gitlab-com/gl-infra/reliability/-/issues/10248
  // as such, we only record this utilisation metric on IO subset of the fleet for now.
  tags: ['golang', 'disk_performance_monitoring'],

  // Since each Gitaly node is a SPOF for a subset of repositories, we need to ensure that
  // we have node-level monitoring on these hosts
  nodeLevelMonitoring: true,
  monitoringThresholds: {
    apdexScore: 0.999,
    errorRatio: 0.9995,
    component_node: {
      apdexScore: 0.97,
    },
  },
  otherThresholds: {
    // Deployment thresholds are optional, and when they are specified, they are
    // measured against the same multi-burn-rates as the monitoring indicators.
    // When a service is in violation, deployments may be blocked or may be rolled
    // back.
    deployment: {
      apdexScore: 0.999,
      errorRatio: 0.9995,
    },
  },
  serviceDependencies: {
    gitaly: true,
  },
  serviceLevelIndicators: {
    goserver: {
      userImpacting: true,
      featureCategory: 'gitaly',
      description: |||
        This SLI monitors all Gitaly GRPC requests in aggregate, excluding the OperationService.
        GRPC failures which are considered to be the "server's fault" are counted as errors.
        The apdex score is based on a subset of GRPC methods which are expected to be fast.
      |||,

      local apdexSelector = baseSelector {
        grpc_service: { ne: ['gitaly.OperationService'] },
      },
      local mainApdexSelector = apdexSelector {
        grpc_method: { noneOf: gitalyHelper.gitalyApdexIgnoredMethods + gitalyHelper.gitalyApdexSlowMethods },
      },
      local slowMethodApdexSelector = apdexSelector {
        grpc_method: { oneOf: gitalyHelper.gitalyApdexSlowMethods },
      },
      local operationServiceApdexSelector = baseSelector {
        grpc_service: ['gitaly.OperationService'],
      },

      apdex: combined(
        [
          gitalyHelper.grpcServiceApdex(mainApdexSelector),
          gitalyHelper.grpcServiceApdex(slowMethodApdexSelector, satisfiedThreshold=10, toleratedThreshold=30),
          gitalyHelper.grpcServiceApdex(operationServiceApdexSelector, satisfiedThreshold=10, toleratedThreshold=30),
        ]
      ),

      requestRate: rateMetric(
        counter='gitaly_service_client_requests_total',
        selector=baseSelector
      ),

      errorRate: gitalyHelper.gitalyGRPCErrorRate(baseSelector),

      significantLabels: ['fqdn'],

      toolingLinks: [
        toolingLinks.continuousProfiler(service='gitaly'),
        toolingLinks.sentry(projectId=12, variables=['environment']),
        toolingLinks.kibana(title='Gitaly', index='gitaly', slowRequestSeconds=1),
      ],
    },
  },
  capacityPlanning+: {
    components: [
      {
        name: 'node_schedstat_waiting',
        parameters: {
          ignore_outliers: [
            {
              start: '2022-05-23',
              end: '2022-06-15',
            },
            {
              start: '2022-06-25',
              end: '2022-07-01',
            },
            {
              start: '2023-03-31',  // https://gitlab.com/gitlab-com/gl-infra/capacity-planning/-/issues/955#note_1378508854
              end: '2023-05-10',
            },
            {
              end: '2023-06-01',
              start: '2023-05-20',
            },
          ],
        },
      },
      {
        name: 'gitaly_active_node_available_space',
        parameters: {
          changepoints: [
            '2023-09-04',  // https://gitlab.com/gitlab-com/runbooks/-/merge_requests/6160
          ],
          ignore_outliers: [
            {
              start: '2021-01-01',
              end: '2023-07-20',
            },
          ],
        },
      },
    ],
  },
})
