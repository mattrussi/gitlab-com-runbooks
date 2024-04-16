local separateMimirRecordingFiles = (import 'recording-rules/lib/mimir/separate-mimir-recording-files.libsonnet').separateMimirRecordingFiles;
local applicationSlis = (import 'gitlab-slis/library.libsonnet');
local applicationSliAggregations = import 'gitlab-slis/aggregation-sets.libsonnet';
local aggregationSetTransformer = import 'servicemetrics/aggregation-set-transformer.libsonnet';
local monitoredServices = (import 'gitlab-metrics-config.libsonnet').monitoredServices;
local recordingRuleRegistry = import 'servicemetrics/recording-rule-registry.libsonnet';
local mimirAggregationSets = import 'mimir-aggregation-sets.libsonnet';

local thanosCompatibilityLabels = { monitor: 'global' };

local transformRuleGroups(sourceAggregationSet, targetAggregationSet, extraSourceSelector, extrasForGroup={}) =
  aggregationSetTransformer.generateRecordingRuleGroups(
    sourceAggregationSet=sourceAggregationSet { selector+: extraSourceSelector },
    targetAggregationSet=targetAggregationSet,
    extrasForGroup=extrasForGroup,
  );

local groupsForApplicationSli(sli, extraSelector) =
  // local targetAggregationSet = applicationSliAggregations.targetAggregationSet(sli, extraStaticLabels=thanosCompatibilityLabels);
  local targetAggregationSet = applicationSliAggregations.targetAggregationSet(sli, extraStaticLabels=mimirAggregationSets.applicationSLIs.recordingRuleStaticLabels);
  local sourceAggregationSet = applicationSliAggregations.sourceAggregationSet(sli, recordingRuleRegistry=recordingRuleRegistry.unifiedRegistry);
  transformRuleGroups(sourceAggregationSet, targetAggregationSet, extraSelector);

local outputPromYaml(groups) =
  std.manifestYamlDoc({
    groups: groups,
  });

// Application SLIs not used in the service catalog  will be aggregated here.
// These aggregations allow us to see what the metrics look like before adding
// an them, so we can validate they would not trigger alerts.
// If the application SLI is added to the service catalog, it will automatically
// generate `sli_aggregation:` recordings that can be reused everywhere. So no
// real need to duplicate them.
std.foldl(
  function(memo, serviceDefinition)
    local slis = mimirAggregationSets.applicationSLIs.slisForService(serviceDefinition);
    memo + separateMimirRecordingFiles(
      function(service, selector, _extraArgs)
        local groups = std.flatMap(
          function(sli)
            groupsForApplicationSli(applicationSlis.get(sli.name), selector { type: service.type }),
          slis
        );
        {
          [if std.length(groups) > 0 then 'aggregated-application-sli-metrics']: outputPromYaml(groups),
        },
      serviceDefinition=serviceDefinition
    )
  ,
  monitoredServices,
  {}
)
