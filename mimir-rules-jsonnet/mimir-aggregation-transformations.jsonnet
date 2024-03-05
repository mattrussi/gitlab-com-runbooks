local separateMimirRecordingFiles = (import 'recording-rules/lib/mimir/separate-mimir-recording-files.libsonnet').separateMimirRecordingFiles;
local monitoredServices = (import 'gitlab-metrics-config.libsonnet').monitoredServices;
local aggregationSets = import 'mimir-aggregation-sets.libsonnet';
local aggregationSetTransformer = import 'servicemetrics/aggregation-set-transformer.libsonnet';

local outputPromYaml(groups) =
  std.manifestYamlDoc({ groups: groups });

local transformedAggregationSets =
  std.filter(
    function(aggregationSet)
      aggregationSet.sourceAggregationSet != null,
    std.objectValues(aggregationSets)
  );
local servicesWithSlis = std.filter(function(service) std.length(service.listServiceLevelIndicators()) > 0, monitoredServices);

local transformRuleGroups(aggregationSet, extraSourceSelector, service) =
  local sourceSelector = extraSourceSelector { type: service.type };
  local source = aggregationSet.sourceAggregationSet { selector+: sourceSelector };
  aggregationSetTransformer.generateRecordingRuleGroups(
    sourceAggregationSet=source,
    targetAggregationSet=aggregationSet,
    extrasForGroup={}
  );

local aggregationsForService(service, selector, _extraArgs) =
  std.foldl(
    function(memo, aggregationSet)
      memo {
        ['transformed-%s-aggregation' % [aggregationSet.id]]: outputPromYaml(transformRuleGroups(aggregationSet, selector, service)),
      },
    transformedAggregationSets,
    {}
  );

std.foldl(
  function(memo, service)
    memo + separateMimirRecordingFiles(
      aggregationsForService,
      service,
    ),
  servicesWithSlis,
  {}
)
