local aggregationSets = import 'gitlab-slis/aggregation-sets.libsonnet';
local library = import 'gitlab-slis/library.libsonnet';
local sliDefinition = import 'gitlab-slis/sli-definition.libsonnet';
local aggregationSetTransformer = import 'servicemetrics/aggregation-set-transformer.libsonnet';

local rulesForSli(sli, aggregationSet, extraSelector) =
  std.flatMap(function(burnRate)
                local apdex = if sli.hasApdex() then
                  [
                    {
                      record: aggregationSet.getApdexWeightMetricForBurnRate(burnRate, required=true),
                      expr: sli.aggregatedApdexOperationRateQuery(
                        aggregationSet.selector + extraSelector,
                        aggregationLabels=aggregationSet.labels,
                        rangeInterval=burnRate
                      ),
                    },
                    {
                      record: aggregationSet.getApdexSuccessRateMetricForBurnRate(burnRate, required=true),
                      expr: sli.aggregatedApdexSuccessRateQuery(
                        aggregationSet.selector + extraSelector,
                        aggregationLabels=aggregationSet.labels,
                        rangeInterval=burnRate
                      ),
                    },
                  ]
                else
                  [];

                apdex + if sli.hasErrorRate() then
                  [
                    {
                      record: aggregationSet.getOpsRateMetricForBurnRate(burnRate, required=true),
                      expr: sli.aggregatedOperationRateQuery(
                        aggregationSet.selector + extraSelector,
                        aggregationLabels=aggregationSet.labels,
                        rangeInterval=burnRate
                      ),
                    },
                    {
                      record: aggregationSet.getErrorRateMetricForBurnRate(burnRate, required=true),
                      expr: sli.aggregatedErrorRateQuery(
                        aggregationSet.selector + extraSelector,
                        aggregationLabels=aggregationSet.labels,
                        rangeInterval=burnRate
                      ),
                    },
                  ]
                else
                  [],
              aggregationSet.getBurnRates());

local groupForSli(sli, extraSelector) =
  local sourceSet = aggregationSets.sourceAggregationSet(sli);
  {
    name: 'Application Defined SLI Rules: %s' % [sli.name],
    interval: '1m',
    rules: rulesForSli(sli, sourceSet, extraSelector),
  };

// Avoiding rules that would already be generated as part of the sli_aggregations.
// The global rules will also reuse those aggregations
local rules(extraSelector={}) =
  {
    groups: std.filterMap(
      function(sli)
        !sli.inRecordingRuleRegistry,
      function(sli)
        groupForSli(sli, extraSelector),
      library.all
    ),
  };

rules
