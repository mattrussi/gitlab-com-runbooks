local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local rateMetric = metricsCatalog.rateMetric;
local toolingLinks = import 'toolinglinks/toolinglinks.libsonnet';

metricsCatalog.serviceDefinition({
  type: 'kubernetes-agent',
  tier: 'sv',
  // contractualThresholds: {
  //   apdexRatio: 0.95,
  //   errorRatio: 0.05,
  // },
  monitoringThresholds: {
    // apdexScore: 0.95,
    errorRatio: 0.95,
  },
  serviceDependencies: {
    gitaly: true,
  },
  provisioning: {
    kubernetes: true,
    vms: false,
  },
  kubeResources: {
    'kubernetes-agent': {
      kind: 'Deployment',
      containers: [
        'kas',
      ],
    },
  },
  serviceLevelIndicators: {
    grpc_requests: {
      userImpacting: true,
      featureCategory: 'not_owned',
      team: 'sre_coreinfra',
      local baseSelector = {
        job: 'gitlab-kas',
      },
      //apdex: histogramApdex(
      //histogram='',
      //selector=baseSelector
      //),
      requestRate: rateMetric(
        counter='grpc_server_handled_total',
        selector=baseSelector
      ),

      errorRate: rateMetric(
        counter='grpc_server_handled_total',
        selector=baseSelector { grpc_code: { ne: 'OK' } }
      ),
      significantLabels: [],
      toolingLinks: [
        toolingLinks.sentry(slug='gitlab/kas'),
        toolingLinks.kibana(title='KAS', index='kas', type='kas'),
      ],
    },
  },
})
