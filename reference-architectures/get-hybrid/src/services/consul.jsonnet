local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local toolingLinks = import 'toolinglinks/toolinglinks.libsonnet';
local kubeLabelSelectors = metricsCatalog.kubeLabelSelectors;

metricsCatalog.serviceDefinition({
  type: 'consul',
  tier: 'sv',
  provisioning: {
    vms: true,
    kubernetes: true,
  },
  kubeConfig: {
    labelSelectors: kubeLabelSelectors(
      podSelector={ namespace: 'consul' },
      hpaSelector=null,
      nodeSelector=null,
      ingressSelector=null,
      deploymentSelector=null
    ),
  },
  serviceLevelIndicators: {
    // No SLIs for now
  },
})
