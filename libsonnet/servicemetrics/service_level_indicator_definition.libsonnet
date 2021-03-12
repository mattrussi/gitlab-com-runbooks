local aggregations = import 'promql/aggregations.libsonnet';
local selectors = import 'promql/selectors.libsonnet';
local toolingLinks = import 'toolinglinks/toolinglinks.libsonnet';
local strings = import 'utils/strings.libsonnet';

// For now we assume that services are provisioned on vms and not kubernetes
// Please consult the README.md file for details of team and feature_category
local serviceLevelIndicatorDefaults = {
  featureCategory: 'not_owned',
  team: null,
  description: '',
  staticLabels: {},  // by default, no static labels
  serviceAggregation: true,  // by default, requestRate is aggregated up to the service level
  ignoreTrafficCessation: false,  // Override to true to disable alerting when SLI is zero or absent
};

local validateHasField(object, field, message) =
  if std.objectHas(object, field) then
    object
  else
    std.assertEqual(true, { __assert: message });

local validateAndApplySLIDefaults(sliName, component, inheritedDefaults) =
  inheritedDefaults
  +
  serviceLevelIndicatorDefaults
  +
  // All components must have a requestRate measurement, since
  // we filter out low-RPS alerts for apdex monitoring and require the RPS for error ratios
  validateHasField(component, 'requestRate', '%s component requires a requestRate measurement' % [sliName])
  +
  validateHasField(component, 'significantLabels', '%s component requires a significantLabels attribute' % [sliName])
  +
  validateHasField(component, 'userImpacting', '%s component requires a userImpacting attribute' % [sliName])
  {
    name: sliName,
  };

// Given an array of labels to aggregate by, filters out those that exist in the staticLabels hash
local filterStaticLabelsFromAggregationLabels(aggregationLabels, staticLabelsHash) =
  std.filter(function(label) !std.objectHas(staticLabelsHash, label), aggregationLabels);

// Definition of a service level indicator
local serviceLevelIndicatorDefinition(sliName, serviceLevelIndicator) =
  serviceLevelIndicator {
    // Returns true if this serviceLevelIndicator allows detailed breakdowns
    // this is not the case for combined serviceLevelIndicator definitions
    supportsDetails(): true,

    hasApdex():: std.objectHas(serviceLevelIndicator, 'apdex'),
    hasRequestRate():: true,  // requestRate is mandatory
    hasAggregatableRequestRate():: std.objectHasAll(serviceLevelIndicator.requestRate, 'aggregatedRateQuery'),
    hasErrorRate():: std.objectHas(serviceLevelIndicator, 'errorRate'),

    hasToolingLinks()::
      std.objectHasAll(serviceLevelIndicator, 'toolingLinks'),

    getToolingLinks()::
      if self.hasToolingLinks() then
        self.toolingLinks
      else
        [],

    renderToolingLinks()::
      toolingLinks.renderLinks(self.getToolingLinks()),

    // Generate recording rules for apdex
    generateApdexRecordingRules(burnRate, recordingRuleNames, aggregationLabels, recordingRuleStaticLabels)::
      local allStaticLabels = recordingRuleStaticLabels + serviceLevelIndicator.staticLabels;
      local aggregationLabelsWithoutStaticLabels = filterStaticLabelsFromAggregationLabels(aggregationLabels, allStaticLabels);

      if self.hasApdex() then
        local apdexSuccessRateExpr = serviceLevelIndicator.apdex.apdexSuccessRateQuery(
          aggregationLabels=aggregationLabelsWithoutStaticLabels,
          selector={},
          rangeInterval=burnRate
        );

        local apdexWeightExpr = serviceLevelIndicator.apdex.apdexWeightQuery(
          aggregationLabels=aggregationLabelsWithoutStaticLabels,
          selector={},
          rangeInterval=burnRate
        );

        (
          if recordingRuleNames.apdexSuccessRate != null then
            [{
              record: recordingRuleNames.apdexSuccessRate,
              labels: allStaticLabels,
              expr: apdexSuccessRateExpr,
            }]
          else
            []
        )
        +
        (
          if recordingRuleNames.apdexWeight != null then
            [{
              record: recordingRuleNames.apdexWeight,
              labels: allStaticLabels,
              expr: apdexWeightExpr,
            }]
          else
            []
        )
      else
        [],

    // Generate recording rules for request rate
    generateRequestRateRecordingRules(burnRate, recordingRuleName, aggregationLabels, recordingRuleStaticLabels)::
      local allStaticLabels = recordingRuleStaticLabels + serviceLevelIndicator.staticLabels;

      [{
        record: recordingRuleName,
        labels: allStaticLabels,
        expr: serviceLevelIndicator.requestRate.aggregatedRateQuery(
          aggregationLabels=filterStaticLabelsFromAggregationLabels(aggregationLabels, allStaticLabels),
          selector={},
          rangeInterval=burnRate
        ),
      }],

    // Generate recording rules for error rate
    generateErrorRateRecordingRules(burnRate, recordingRuleName, aggregationLabels, recordingRuleStaticLabels)::
      local allStaticLabels = recordingRuleStaticLabels + serviceLevelIndicator.staticLabels;

      if self.hasErrorRate() then
        [{
          record: recordingRuleName,
          labels: allStaticLabels,
          expr: serviceLevelIndicator.errorRate.aggregatedRateQuery(
            aggregationLabels=filterStaticLabelsFromAggregationLabels(aggregationLabels, allStaticLabels),
            selector={},
            rangeInterval=burnRate
          ),
        }]
      else
        [],
  };

{
  serviceLevelIndicatorDefinition(serviceLevelIndicator)::
    {
      initServiceLevelIndicatorWithName(sliName, inheritedDefaults)::
        serviceLevelIndicatorDefinition(sliName, validateAndApplySLIDefaults(sliName, serviceLevelIndicator, inheritedDefaults)),
    },
}
