local separateMimirRecordingFiles = (import 'recording-rules/lib/mimir/separate-mimir-recording-files.libsonnet').separateMimirRecordingFiles;
local applicationSlis = (import 'gitlab-slis/library.libsonnet').all;
local applicationSliAggregations = import 'gitlab-slis/aggregation-sets.libsonnet';
local aggregationSetTransformer = import 'servicemetrics/aggregation-set-transformer.libsonnet';

local transformRuleGroups(sourceAggregationSet, targetAggregationSet, extraSourceSelector, extrasForGroup={}) =
  aggregationSetTransformer.generateRecordingRuleGroups(
    sourceAggregationSet=sourceAggregationSet { selector+: extraSourceSelector },
    targetAggregationSet=targetAggregationSet,
    extrasForGroup=extrasForGroup,
  );


local groupsForApplicationSli(sli, extraSelector) =
  local targetAggregationSet = applicationSliAggregations.targetAggregationSet(sli);
  local sourceAggregationSet = applicationSliAggregations.sourceAggregationSet(sli);
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
separateMimirRecordingFiles(
  function(_service, selector, _extraArgs)
    {
      'aggregated-application-sli-metrics': outputPromYaml(
        std.flatMap(
          function(sli)
            groupsForApplicationSli(sli, selector),
          applicationSlis
        )
      ),
    }
)
