local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local sliLibrary = import 'gitlab-slis/library.libsonnet';

metricsCatalog.serviceDefinition({
  type: 'ai-abstraction-layer',
  tier: 'sv',
  /* The AI abstraction layer is not an additional infrastructure component,
     it lives in the monolith and it's backed by our existing services (see
     `serviceDependencies` bellow) */
  provisioning: { vms: false, kubernetes: false },
  serviceLevelIndicators: sliLibrary.get('llm_completion').generateServiceLevelIndicator({}, {}),
  serviceDependencies: {
    api: true,
    sidekiq: true,
  },
})
