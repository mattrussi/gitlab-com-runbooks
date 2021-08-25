local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local rateMetric = metricsCatalog.rateMetric;
local toolingLinks = import 'toolinglinks/toolinglinks.libsonnet';

metricsCatalog.serviceDefinition({
  type: 'kas',
  tier: 'sv',

  tags: ['golang'],

  monitoringThresholds: {
    // apdexScore: 0.95,
    errorRatio: 0.9995,
  },
  serviceDependencies: {
    gitaly: true,
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
      featureCategory: 'kubernetes_management',
      team: 'sre_coreinfra',
      local baseSelector = {
        job: 'gitlab-kas',
      },

      requestRate: rateMetric(
        counter='grpc_server_handled_total',
        selector=baseSelector
      ),

      errorRate: rateMetric(
        counter='grpc_server_handled_total',
        selector=baseSelector { grpc_code: { nre: 'OK|FailedPrecondition|Unauthenticated|PermissionDenied' }, grpc_method: 'GetConfiguration' }
      ),

      significantLabels: ['grpc_method'],

      toolingLinks: [
        toolingLinks.sentry(slug='gitlab/kas'),
        toolingLinks.kibana(title='Kubernetes Agent Server', index='kas', type='kas'),
      ],
    },
  },
})
