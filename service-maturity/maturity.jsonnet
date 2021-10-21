local evaluator = import 'service-maturity/evaluator.libsonnet';
local levels = import 'service-maturity/levels.libsonnet';
local metricsCatalog = import 'servicemetrics/metrics-catalog.libsonnet';

local serviceMaturityManifest(service) =
  {
    level: evaluator.maxLevel(service, levels.getLevels()),
    details: evaluator.evaluate(service, levels.getLevels()),
  };

std.foldl(
  function(accumulator, service) accumulator {
    [service.type]: serviceMaturityManifest(service),
  },
  metricsCatalog.services,
  {}
)
