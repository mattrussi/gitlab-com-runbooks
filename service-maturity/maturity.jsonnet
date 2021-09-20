local evaluator = import 'service-maturity/evaluator.libsonnet';
local levels = import 'service-maturity/levels.libsonnet';
local metricsCatalog = import 'servicemetrics/metrics-catalog.libsonnet';

std.foldl(
  function(accumulator, service) accumulator { [service.type]: evaluator.evaluate(service, levels.getLevels()) },
  metricsCatalog.services,
  {}
)
