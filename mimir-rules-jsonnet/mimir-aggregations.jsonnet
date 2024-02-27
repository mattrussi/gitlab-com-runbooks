local separateMimirRecordingFiles = (import 'recording-rules/lib/mimir/separate-mimir-recording-files.libsonnet').separateMimirRecordingFiles;
local monitoredServices = (import 'gitlab-metrics-config.libsonnet').monitoredServices;
local recordingRules = import 'recording-rules/recording-rules.libsonnet';
local aggregationSets = import 'mimir-aggregation-sets.libsonnet';
local intervalForDuration = import 'servicemetrics/interval-for-duration.libsonnet';
local recordingRuleRegistry = import 'servicemetrics/recording-rule-registry.libsonnet';

local outputPromYaml(groups) =
  std.manifestYamlDoc({ groups: groups });

local generatorsForService(aggregationSet, burnRate, extraSelector) = [
  recordingRules.componentMetricsRuleSetGenerator(
    burnRate=burnRate,
    aggregationSet=aggregationSet,
    extraSourceSelector=extraSelector,
    config={ recordingRuleRegistry: recordingRuleRegistry.unifiedRegistry },
  ),
];

local groupsForService(service, aggregationSet, extraSelector) =
  std.map(
    function(burnRate)
      {
        name: '%s: %s - Burn-Rate %s' % [aggregationSet.name, service.type, burnRate],
        interval: intervalForDuration.intervalForDuration(burnRate),
        rules: std.flatMap(
          function(generator)
            generator.generateRecordingRulesForService(service),
          generatorsForService(aggregationSet, burnRate, extraSelector)
        ),
      },
    aggregationSet.getBurnRates(),
  );


local aggregationsForService(service, selector, _extraArgs) =
  local set = aggregationSets.componentSLIs;
  {
    ['%s-aggregation' % set.id]: outputPromYaml(groupsForService(service, set, selector)),
  };

local servicesWithSlis = std.filter(function(service) std.length(service.listServiceLevelIndicators()) > 0, monitoredServices);
std.foldl(
  function(memo, service)
    memo + separateMimirRecordingFiles(
      aggregationsForService,
      service,
    ),
  servicesWithSlis,
  {}
)
