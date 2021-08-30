local metricsCatalog = import 'gitlab-monitoring/servicemetrics/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;

{
  // This calculates the apdex score for a Gitaly-like (Gitaly/Praefect)
  // GRPC service. Since this is an SLI only, not all operations are included,
  // only unary ones, and even then known slow operations are excluded from
  // the apdex calculation
  grpcServiceApdex(baseSelector)::
    histogramApdex(
      histogram='grpc_server_handling_seconds_bucket',
      selector=baseSelector {
        grpc_type: 'unary',
      },
      satisfiedThreshold=0.5,
      toleratedThreshold=1
    ),
}
