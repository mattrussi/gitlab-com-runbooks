local registryArchetype = import 'service-archetypes/registry-archetype.libsonnet';
local registryCustomRouteSLIs = import './lib/registry-custom-route-slis.libsonnet';
local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local rateMetric = metricsCatalog.rateMetric;
local gitalyHelper = import 'service-archetypes/helpers/gitaly.libsonnet';
local kubeLabelSelectors = metricsCatalog.kubeLabelSelectors;
local kubeResourceName='gitlab-registry';

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
    nodeLevelMonitoring=false,
  )
)
