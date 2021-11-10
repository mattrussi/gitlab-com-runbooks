local aggregationSets = import 'gitlab-slis/aggregation-sets.libsonnet';
local library = import 'gitlab-slis/library.libsonnet';
local sliDefinition = import 'gitlab-slis/sli-definition.libsonnet';

local rulesForSli(sli, aggregationSet) =
  if sli.kind == sliDefinition.apdexKind then
    std.flatMap(function(burnRate)
      [
        {
          record: aggregationSet.getApdexWeightMetricForBurnRate(burnRate),
          expr: sli.aggregatedOperationRateQuery(
            aggregationSet.selector,
            aggregationLabels=aggregationSet.labels,
            rangeInterval=burnRate
          ),
        },
        {
          record: aggregationSet.getApdexSuccessRateMetricForBurnRate(burnRate),
          expr: sli.aggregatedSuccessRateQuery(
            aggregationSet.selector,
            aggregationLabels=aggregationSet.labels,
            rangeInterval=burnRate
          ),
        },
      ], aggregationSet.getBurnRates())
  else [];

local groupForSli(sli) =
  local sourceSet = aggregationSets.sourceAggregationSet(sli);
  {
    name: 'Application Defined SLI Rules: %s' % [sli.name],
    interval: '1m',
    rules: rulesForSli(sli, sourceSet),
  };

// Avoiding rules that would already be generated as part of the sli_aggregations.
// The global rules will also reuse those aggregations
local rules = {
  groups: std.filterMap(
    function(sli)
      !sli.inRecordingRuleRegistry,
    groupForSli,
    library.all
  ),
};

{
  'gitlab-application-slis.yml': std.manifestYamlDoc(rules),
}
