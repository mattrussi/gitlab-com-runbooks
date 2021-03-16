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
  upscaleLongerBurnRates: false,  // When true, long-term burn rates will be upscaled from shorter burn rates, to optimize for high cardinality metrics
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
    generateApdexRecordingRules(burnRate, aggregationSet, aggregationLabels, recordingRuleStaticLabels)::
      local upscaleLabels =
        if self.upscaleLongerBurnRates && burnRate == '1h' then
          { upscale_source: 'yes' }
        else
          {};

      local allStaticLabels = recordingRuleStaticLabels + serviceLevelIndicator.staticLabels + upscaleLabels;
      local aggregationLabelsWithoutStaticLabels = filterStaticLabelsFromAggregationLabels(aggregationLabels, allStaticLabels);

      if self.hasApdex() then
        // Currently we only do upscaling on apdex scores and on 6h burn rates
        if self.upscaleLongerBurnRates && burnRate == '6h' then
          /* Do not generate source aggregations for upscaleLongerBurnRates components */
          []
        else
          local apdexSuccessRateRecordingRuleName = aggregationSet.getApdexSuccessRateMetricForBurnRate(burnRate);
          local apdexWeightRecordingRuleName = aggregationSet.getApdexWeightMetricForBurnRate(burnRate);
          local apdexRatioRecordingRuleName = aggregationSet.getApdexRatioMetricForBurnRate(burnRate);

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
            if apdexSuccessRateRecordingRuleName != null then
              [{
                record: apdexSuccessRateRecordingRuleName,
                labels: allStaticLabels,
                expr: apdexSuccessRateExpr,
              }]
            else
              []
          )
          +
          (
            if apdexWeightRecordingRuleName != null then
              [{
                record: apdexWeightRecordingRuleName,
                labels: allStaticLabels,
                expr: apdexWeightExpr,
              }]
            else
              []
          )
      else
        [],

    // Generate recording rules for request rate
    generateRequestRateRecordingRules(burnRate, aggregationSet, aggregationLabels, recordingRuleStaticLabels)::
      local requestRateRecordingRuleName = aggregationSet.getOpsRateMetricForBurnRate(burnRate, required=true);
      local allStaticLabels = recordingRuleStaticLabels + serviceLevelIndicator.staticLabels;

      [{
        record: requestRateRecordingRuleName,
        labels: allStaticLabels,
        expr: serviceLevelIndicator.requestRate.aggregatedRateQuery(
          aggregationLabels=filterStaticLabelsFromAggregationLabels(aggregationLabels, allStaticLabels),
          selector={},
          rangeInterval=burnRate
        ),
      }],

    // Generate recording rules for error rate
    generateErrorRateRecordingRules(burnRate, aggregationSet, aggregationLabels, recordingRuleStaticLabels)::
      if self.hasErrorRate() then
        local allStaticLabels = recordingRuleStaticLabels + serviceLevelIndicator.staticLabels;
        local requestRateRecordingRuleName = aggregationSet.getOpsRateMetricForBurnRate(burnRate, required=true);
        local errorRateRecordingRuleName = aggregationSet.getErrorRateMetricForBurnRate(burnRate, required=true);
        local filteredAggregationLabels = filterStaticLabelsFromAggregationLabels(aggregationLabels, allStaticLabels);

        local expr = serviceLevelIndicator.errorRate.aggregatedRateQuery(
          aggregationLabels=filterStaticLabelsFromAggregationLabels(aggregationLabels, allStaticLabels),
          selector={},
          rangeInterval=burnRate
        );
        [{
          record: errorRateRecordingRuleName,
          labels: allStaticLabels,
          expr: |||
            (
              %(expr)s
            )
            or
            (
              0 * group by(%(filteredAggregationLabels)s) (
                %(requestRateRecordingRuleName)s{%(allStaticLabels)s}
              )
            )
          ||| % {
            expr: strings.indent(expr, 2),
            filteredAggregationLabels: aggregations.serialize(filteredAggregationLabels),
            requestRateRecordingRuleName: requestRateRecordingRuleName,
            allStaticLabels: selectors.serializeHash(allStaticLabels),
          },
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
