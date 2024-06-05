local registryCustomRouteSLIs = import './lib/registry-custom-route-slis.libsonnet';
local registryArchetype = import 'service-archetypes/registry-archetype.libsonnet';
local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local rateMetric = metricsCatalog.rateMetric;
local kubeLabelSelectors = metricsCatalog.kubeLabelSelectors;
local kubeResourceName = 'gitlab-registry';

local customRouteSLIs = registryCustomRouteSLIs.customApdexRouteConfig;

metricsCatalog.serviceDefinition(
  registryArchetype(
    customRouteSLIs=customRouteSLIs,
    defaultRegistryComponent='server',
    kubeConfig={
      local kubeSelector = { app: 'registry' },
      labelSelectors: kubeLabelSelectors(
        podSelector=kubeSelector,
        hpaSelector={ horizontalpodautoscaler: kubeResourceName },
        nodeSelector=null,  // Runs in the workload=support pool, not a dedicated pool
        ingressSelector=kubeSelector,
        deploymentSelector=kubeSelector
      ),
    },
    kubeResourceName=kubeResourceName,
  ) {
    // A 98% confidence interval will be used for all SLIs on this service
    useConfidenceLevelForSLIAlerts: '98%',
  }
)
