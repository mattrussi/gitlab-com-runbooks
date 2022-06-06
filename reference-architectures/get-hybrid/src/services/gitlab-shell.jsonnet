local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local rateMetric = metricsCatalog.rateMetric;
local gitalyHelper = import 'service-archetypes/helpers/gitaly.libsonnet';
local kubeLabelSelectors = metricsCatalog.kubeLabelSelectors;

metricsCatalog.serviceDefinition({
  type: 'gitlab-shell',
  tier: 'sv',

  tags: [],  // Once we start scraping the golang process, we should add the `golang` tag here

  nodeLevelMonitoring: false,
  monitoringThresholds: {
    apdexScore: 0.999,
    errorRatio: 0.999,
  },
  provisioning: {
    vms: false,
    kubernetes: true,
  },
  regional: false,
  kubeConfig: {
    local kubeSelector = { app: 'gitlab-shell' },
    labelSelectors: kubeLabelSelectors(
      podSelector=kubeSelector,
      hpaSelector={ horizontalpodautoscaler: 'gitlab-gitlab-shell' },
      nodeSelector=null,  // Runs in the workload=support pool, not a dedicated pool
      ingressSelector=null,  // This may need to be updated if GET moved away from the current NodePort implementation
      deploymentSelector=kubeSelector
    ),
  },
  kubeResources: {
    'gitlab-gitlab-shell': {
      kind: 'Deployment',
      containers: [
        'gitlab-shell',
      ],
    },
  },
  serviceLevelIndicators: {
    // TODO: use a better metric than GPRC calls in future.
    // see https://gitlab.com/gitlab-com/runbooks/-/issues/88 for more details.
    grpc_requests: {
      userImpacting: true,
      description: |||
        A proxy measurement of the number of GRPC SSH service requests made to Gitaly and Praefect.

        Since we are unable to measure gitlab-shell directly at present, this is the best substitute we can provide.
      |||,

      local baseSelector = {
        job: 'gitaly',  // Looking for gitaly let the check to work with and without Praefect in the cluster.
        grpc_service: 'gitaly.SSHService',
      },

      apdex: gitalyHelper.grpcServiceApdex(baseSelector, satisfiedThreshold=30, toleratedThreshold=60),

      requestRate: rateMetric(
        counter='gitaly_service_client_requests_total',
        selector=baseSelector
      ),

      errorRate: rateMetric(
        counter='grpc_server_handled_total',
        selector=baseSelector { grpc_code: { ne: 'OK' } },
      ),

      significantLabels: ['node'],

      toolingLinks: [],
    },
  },
})
