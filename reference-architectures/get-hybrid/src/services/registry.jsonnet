local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local rateMetric = metricsCatalog.rateMetric;
local gitalyHelper = import 'service-archetypes/helpers/gitaly.libsonnet';
local registryHelpers = import './lib/registry-helpers.libsonnet';
local registryBaseSelector = registryHelpers.registryBaseSelector;
local defaultRegistrySLIProperties = registryHelpers.defaultRegistrySLIProperties;
local kubeLabelSelectors = metricsCatalog.kubeLabelSelectors;
local histogramApdex = metricsCatalog.histogramApdex;

metricsCatalog.serviceDefinition({
  type: 'registry',
  tier: 'sv',

  tags: ['golang'],

  nodeLevelMonitoring: false,
  monitoringThresholds: {
    apdexScore: 0.997,
    errorRatio: 0.9999,
  },
  provisioning: {
    vms: false,
    kubernetes: true,
  },
  regional: false,
  kubeConfig: {
    local kubeSelector = { app: 'registry' },
    labelSelectors: kubeLabelSelectors(
      podSelector=kubeSelector,
      hpaSelector={ horizontalpodautoscaler: 'gitlab-registry' },
      nodeSelector=null,  // Runs in the workload=support pool, not a dedicated pool
      ingressSelector=kubeSelector,
      deploymentSelector=kubeSelector
    ),
  },
  kubeResources: {
    'gitlab-registry': {
      kind: 'Deployment',
      containers: [
        'registry',
      ],
    },
  },

  serviceLevelIndicators: {
    server: defaultRegistrySLIProperties {
      userImpacting: true,
      description: |||
        Aggregation of all registry HTTP requests.
      |||,

      apdex: registryHelpers.mainApdex(),

      requestRate: rateMetric(
        counter='registry_http_requests_total',
        selector=registryBaseSelector
      ),

      errorRate: rateMetric(
        counter='registry_http_requests_total',
        selector=registryBaseSelector {
          code: { re: '5..' },
        }
      ),

      significantLabels: ['route', 'method'],

      toolingLinks: [
      ],
    },
  } + registryHelpers.apdexPerRoute,
})
