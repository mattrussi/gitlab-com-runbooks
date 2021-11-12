local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local rateMetric = metricsCatalog.rateMetric;
local customApdex = metricsCatalog.customApdex;
local combined = metricsCatalog.combined;
local gitalyHelpers = import './lib/gitaly-helpers.libsonnet';
local toolingLinks = import 'toolinglinks/toolinglinks.libsonnet';

// This is a list of unary GRPC methods that should not be included in measuring the apdex score
// for the Gitaly service, since they're called from background jobs and the latency
// does not reflect the overall latency of the Gitaly server
local gitalyApdexIgnoredMethods = std.set([
  'CalculateChecksum',
  'CommitLanguages',
  'CreateFork',
  'CreateRepositoryFromURL',
  'FetchInternalRemote',
  'FetchRemote',
  'FindRemoteRepository',
  'FindRemoteRootRef',
  'Fsck',
  'GarbageCollect',
  'RepackFull',
  'RepackIncremental',
  'ReplicateRepository',
  'FetchIntoObjectPool',
  'FetchSourceBranch',
  'OptimizeRepository',
  'CommitStats',  // https://gitlab.com/gitlab-org/gitlab/-/issues/337080

  // PackObjectsHookWithSidechannel and PostUploadPackWithSidechannel are
  // used to serve 'git fetch' traffic. Their latency is proportional to
  // the size of the size of the fetch and the download speed of the
  // client.
  'PackObjectsHookWithSidechannel',
  'PostUploadPackWithSidechannel',

  // Excluding Hook RPCs, as these are dependent on the internal Rails API.
  // Almost all time is spend there, once it's slow of failing it's usually not
  // a Gitaly alert that should fire.
  'PreReceiveHook',
  'PostReceiveHook',
  'UpdateHook',
]);

// local gitalyOpServiceApdexIgnoredMethods = std.set([]);
local gitalyApdexIgnoredMethodsRegexp = std.join('|', gitalyApdexIgnoredMethods);
// local gitalyOpServiceApdexIgnoredMethodsRegexp = std.join('|', gitalyOpServiceApdexIgnoredMethods);

local gitalyGRPCErrorRate(baseSelector) =
  combined([
    rateMetric(
      counter='gitaly_service_client_requests_total',
      selector=baseSelector {
        grpc_code: { nre: 'OK|NotFound|Unauthenticated|AlreadyExists|FailedPrecondition|DeadlineExceeded|Canceled|InvalidArgument' },
      }
    ),
    rateMetric(
      counter='gitaly_service_client_requests_total',
      selector=baseSelector {
        grpc_code: 'DeadlineExceeded',
        deadline_type: { ne: 'limited' },
      }
    ),
  ]);

metricsCatalog.serviceDefinition({
  type: 'gitaly',
  tier: 'stor',

  // disk_performance_monitoring requires disk utilisation metrics are currently reporting correctly for
  // HDD volumes, see https://gitlab.com/gitlab-com/gl-infra/infrastructure/-/issues/10248
  // as such, we only record this utilisation metric on IO subset of the fleet for now.
  tags: ['golang', 'disk_performance_monitoring'],

  // Since each Gitaly node is a SPOF for a subset of repositories, we need to ensure that
  // we have node-level monitoring on these hosts
  nodeLevelMonitoring: true,
  monitoringThresholds: {
    apdexScore: 0.999,
    errorRatio: 0.9995,
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

      local baseSelector = {
        job: 'gitaly',
        grpc_service: { ne: 'gitaly.OperationService' },
      },
      local baseSelectorApdex = baseSelector {
        grpc_method: { nre: gitalyApdexIgnoredMethodsRegexp },
      },

      apdex: gitalyHelpers.grpcServiceApdex(baseSelectorApdex),

      requestRate: rateMetric(
        counter='gitaly_service_client_requests_total',
        selector=baseSelector
      ),

      errorRate: gitalyGRPCErrorRate(baseSelector),

      significantLabels: ['fqdn'],

      toolingLinks: [
        toolingLinks.continuousProfiler(service='gitaly'),
        toolingLinks.sentry(slug='gitlab/gitaly-production'),
        toolingLinks.kibana(title='Gitaly', index='gitaly', slowRequestSeconds=1),
      ],
    },

    // Gitaly's OperationService communicates with external hooks
    // and therefore has different latency characteristics
    // Since it can also fail in other ways (due to upstream issues on hooks)
    // its useful to treat these methods as a separate component
    goserver_op_service: {
      userImpacting: true,
      featureCategory: 'gitaly',
      description: |||
        This SLI monitors requests to Gitaly's OperationService, via its GRPC endpoint.
        OperationService methods are generally expected to be slower than other Gitaly endpoints
        and this is reflected in the SLI.
      |||,

      local baseSelector = { job: 'gitaly', grpc_service: 'gitaly.OperationService' },
      // The OperationService apdex is disabled primarily to deal with very slow
      // operations producing a lot of alerts.
      // Excluding those RPCs is not a very effective strategy, as OperationService
      // is very low-traffic to begin with, and with every excluded RPC, we increase
      // the sensitivity of the alerts. Thus, we opt to remove this SLO completely
      // for the time being.
      //
      // Infradev issues addressing sources of latency:
      // - https://gitlab.com/gitlab-com/gl-infra/production/-/issues/5311
      //
      //apdex: histogramApdex(
      //  histogram='grpc_server_handling_seconds_bucket',
      //  selector=baseSelector {
      //    grpc_type: 'unary',
      //    grpc_method: { nre: gitalyOpServiceApdexIgnoredMethodsRegexp },
      //  },
      //  satisfiedThreshold=10,
      //  toleratedThreshold=30
      //),

      requestRate: rateMetric(
        counter='gitaly_service_client_requests_total',
        selector=baseSelector
      ),

      errorRate: gitalyGRPCErrorRate(baseSelector),

      significantLabels: ['fqdn'],

      toolingLinks: [
        toolingLinks.kibana(title='Gitaly OperationService', index='gitaly', slowRequestSeconds=30, matches={ 'json.grpc.service': 'gitaly.OperationService' }),
      ],
    },

    gitalyruby: {
      userImpacting: true,
      featureCategory: 'gitaly',
      description: |||
        This SLI monitors requests to Gitaly's Ruby sidecar, known as Gitaly-Ruby. All requests made to
        Gitaly-Ruby are monitored in aggregate, via its GRPC interface.
      |||,

      local baseSelector = { job: 'gitaly' },

      // Uses the goservers histogram, but only selects client unary calls: this is an effective proxy
      // go gitaly-ruby client call times
      apdex: customApdex(
        rateQueryTemplate=|||
          rate(grpc_server_handling_seconds_bucket{%(selector)s}[%(rangeInterval)s]) and on(grpc_service,grpc_method) grpc_client_handled_total{job="gitaly"}
        |||,
        selector=baseSelector {
          grpc_type: 'unary',
          grpc_service: { ne: 'gitaly.OperationService' },
          grpc_method: {
            nre: gitalyApdexIgnoredMethodsRegexp +
                 '|GetLFSPointers|GetAllLFSPointers',  // Ignored because of https://gitlab.com/gitlab-org/gitaly/-/issues/3441
          },
        },
        satisfiedThreshold=10,
        toleratedThreshold=30
      ),

      requestRate: rateMetric(
        counter='grpc_client_handled_total',
        selector=baseSelector
      ),

      errorRate: rateMetric(
        counter='grpc_client_handled_total',
        selector=baseSelector {
          grpc_method: { nre: 'UpdateRemoteMirror|AddRemote' },  // Ignore these calls until https://gitlab.com/gitlab-org/gitlab/-/issues/300884 is fixed
          grpc_code: { nre: 'OK|NotFound|Unauthenticated|AlreadyExists|FailedPrecondition|DeadlineExceeded' },
        }
      ),

      significantLabels: ['fqdn', 'grpc_method'],

      toolingLinks: [
        toolingLinks.sentry(slug='gitlab/gitlabcom-gitaly-ruby'),
        toolingLinks.kibana(title='Gitaly Ruby', index='gitaly', tag='gitaly.ruby'),
      ],
    },
  },
})
