local metricsCatalog = import 'servicemetrics/metrics-catalog.libsonnet';

local uniqServices(saturationPoints) = std.foldl(
  function(memo, definition) std.set(memo + definition.appliesTo),
  std.objectValues(saturationPoints),
  []
);

local servicesEnvMapping(services) = {
  [service]: metricsCatalog.getService(service).capacityPlanningEnvironment
  for service in services
};

{
  uniqServices(saturationPoints): uniqServices(saturationPoints),
  servicesEnvMapping(services): servicesEnvMapping(services),
}
