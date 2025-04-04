local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local rateMetric = metricsCatalog.rateMetric;
local combined = metricsCatalog.combined;
local histogramApdex = metricsCatalog.histogramApdex;

// This is a list of unary GRPC methods that should not be included in measuring the apdex score
// for the Gitaly service, since they're called from background jobs and the latency
// does not reflect the overall latency of the Gitaly server
local gitalyApdexIgnoredMethods = [
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

  // PackObjectsHookWithSidechannel, PostUploadPackWithSidechannel and
  // SSHUploadPackWithSidechannel are used to serve 'git fetch' traffic.
  // Their latency is proportional to the size of the size of the fetch and
  // the download speed of the client.
  'PackObjectsHookWithSidechannel',
  'PostUploadPackWithSidechannel',
  'SSHUploadPackWithSidechannel',

  // Excluding Hook RPCs, as these are dependent on the internal Rails API.
  // Almost all time is spend there, once it's slow of failing it's usually not
  // a Gitaly alert that should fire.
  'PreReceiveHook',
  'PostReceiveHook',
  'UpdateHook',
];

// Ignored because of https://gitlab.com/gitlab-org/gitaly/-/issues/3441
local gitalyRubyApdexIgnoredMethods = gitalyApdexIgnoredMethods + ['GetLFSPointers', 'GetAllLFSPointers'];

// This calculates the apdex score for a Gitaly-like (Gitaly/Praefect)
// GRPC service. Since this is an SLI only, not all operations are included,
// only unary ones, and even then known slow operations are excluded from
// the apdex calculation
local grpcServiceApdex(baseSelector) =
  histogramApdex(
    histogram='grpc_server_handling_seconds_bucket',
    selector=baseSelector {
      grpc_type: 'unary',
    },
    satisfiedThreshold=0.5,
    toleratedThreshold=1
  );

local gitalyGRPCErrorRate(baseSelector) =
  combined([
    rateMetric(
      counter='gitaly_service_client_requests_total',
      selector=baseSelector {
        grpc_code: { noneOf: ['OK', 'NotFound', 'Unauthenticated', 'AlreadyExists', 'FailedPrecondition', 'DeadlineExceeded', 'Canceled', 'InvalidArgument'] },
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


{
  gitalyApdexIgnoredMethods:: gitalyApdexIgnoredMethods,
  gitalyRubyApdexIgnoredMethods:: gitalyRubyApdexIgnoredMethods,

  grpcServiceApdex:: grpcServiceApdex,
  gitalyGRPCErrorRate:: gitalyGRPCErrorRate,
}
