local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local rateMetric = metricsCatalog.rateMetric;
local toolingLinks = import 'toolinglinks/toolinglinks.libsonnet';

metricsCatalog.serviceDefinition({
  type: 'kas',
  tier: 'sv',

  tags: ['golang'],

  monitoringThresholds: {
    apdexScore: 0.95,
    errorRatio: 0.9995,
  },
  otherThresholds: {
    // Deployment thresholds are optional, and when they are specified, they are
    // measured against the same multi-burn-rates as the monitoring indicators.
    // When a service is in violation, deployments may be blocked or may be rolled
    // back.
    deployment: {
      apdexScore: 0.95,
      errorRatio: 0.9995,
    },
  },
  serviceDependencies: {
    api: true,
    gitaly: true,
    kas: true,
    praefect: true,
    redis: true,
  },
  provisioning: {
    kubernetes: true,
    vms: false,
  },
  kubeResources: {
    kas: {
      kind: 'Deployment',
      containers: [
        'kas',
      ],
    },
  },
  serviceLevelIndicators: {
    grpc_requests: {
      userImpacting: true,
      // Do not page SREs for this SLI for now.
      // Once we are comfortable with the Apdex,
      // we can remove it for a default `s2` severity.
      // see https://gitlab.com/gitlab-com/runbooks/-/merge_requests/5526#note_1321200842
      severity: 's4',
      featureCategory: 'kubernetes_management',
      local baseSelector = {
        type: 'kas',
      },

      apdex: histogramApdex(
        histogram='k8s_api_proxy_routing_duration_seconds_bucket',
        selector=baseSelector {
          // The `success` status contains durations up to 20s and
          // the `timeout` would contain everything above that.
          // However, if no agent is connected at the time of the proxy request,
          // (because it simply isn't or is reconnecting) this is NOT an actual
          // issue with KAS itself, but with the customers infrastructure.
          // Therefore, we only select for `success` statuses for now and will
          // look into how we can improve the Apdex score long-term.
          // status: { oneOf: ['success', 'timeout'] },
          status: { oneOf: ['success'] },
        },
        satisfiedThreshold=4.096,
      ),

      requestRate: rateMetric(
        counter='grpc_server_handled_total',
        selector=baseSelector
      ),

      errorRate: rateMetric(
        counter='grpc_server_handled_total',
        selector=baseSelector {
          grpc_code: { nre: '^(OK|NotFound|PaymentRequired|FailedPrecondition|Unauthenticated|PermissionDenied|Canceled|DeadlineExceeded|ResourceExhausted)$' },
          grpc_service: { ne: 'gitlab.agent.kubernetes_api.rpc.KubernetesApi' },
        },
      ),

      significantLabels: ['grpc_method'],

      toolingLinks: [
        toolingLinks.sentry(slug='gitlab/kas'),
        toolingLinks.kibana(title='Kubernetes Agent Server', index='kas', type='kas'),
      ],
    },
  },
})
