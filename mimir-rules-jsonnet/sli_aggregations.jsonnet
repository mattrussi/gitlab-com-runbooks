local monitoredServices = (import 'gitlab-metrics-config.libsonnet').monitoredServices;
local intervalForDuration = import 'servicemetrics/interval-for-duration.libsonnet';
local separateMimirRecordingFiles = (import 'recording-rules/lib/mimir/separate-mimir-recording-files.libsonnet').separateMimirRecordingFiles;
local aggregationSet = import 'servicemetrics/aggregation-set.libsonnet';
local unifiedRegistry = import 'servicemetrics/recording-rule-registry/unified-registry.libsonnet';

local rulesForServiceForBurnRate(serviceDefinition, burnRate, extraSelector) =
  local rules = unifiedRegistry.rulesForServiceForBurnRate(serviceDefinition.type, burnRate, extraSelector);
  if std.length(rules) > 0 then
    {
      name: 'SLI Aggregations: %s - %s burn-rate' % [serviceDefinition.type, burnRate],
      interval: intervalForDuration.intervalForDuration(burnRate),
      rules: rules,
    } else null;

local rulesForService(serviceDefinition, extraSelector) =
  std.prune([
    rulesForServiceForBurnRate(serviceDefinition, burnRate, extraSelector)
    for burnRate in aggregationSet.defaultSourceBurnRates
  ]);

local outputPromYaml(groups) =
  std.manifestYamlDoc({
    groups: groups,
  });

local fileForService(service, extraSelector={}) =
  local ruleGroups = rulesForService(
    service,
    extraSelector
  );
  if std.length(ruleGroups) > 1 then
    {
      'sli-aggregations':
        outputPromYaml(ruleGroups),
    }
  else
    {};

std.foldl(
  function(memo, service)
    memo + separateMimirRecordingFiles(
      function(service, selector, _)
        fileForService(service, extraSelector=selector),
      service,
    ),
  monitoredServices,
  {}
)
