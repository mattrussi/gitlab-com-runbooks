local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local rateMetric = metricsCatalog.rateMetric;
local toolingLinks = import 'toolinglinks/toolinglinks.libsonnet';
local haproxyComponents = import './lib/haproxy_components.libsonnet';
local perFeatureCategoryRecordingRules = (import './lib/puma-per-feature-category-recording-rules.libsonnet').perFeatureCategoryRecordingRules;

metricsCatalog.serviceDefinition({
  type: 'consul',
  tier: 'sv',
  monitoringThresholds: {
  },
  serviceDependencies: {
  },
  provisioning: {
    vms: true,
    kubernetes: true,
  },
  regional: true,
  kubeResources: {
    consul: {
      kind: 'Daemonset',
      containers: [
        'consul',
      ],
    },
  },
  serviceLevelIndicators: {
  },
})
