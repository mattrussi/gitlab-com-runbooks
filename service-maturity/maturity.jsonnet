local evaluator = import './maturity-evaluator.libsonnet';
local levels = import './maturity-levels.libsonnet';
local metricsCatalog = import 'metrics-catalog.libsonnet';

std.foldl(
  function(accumulator, service) accumulator { [service.type]: evaluator.evaluate(service, levels.getLevels()) },
  metricsCatalog.services,
  {}
)
