// WARNING
// This is probably not what you want. Avoid combining multiple signals into
// a single SLI unless you are sure you know what you are doing

local metricsCatalog = import './metrics.libsonnet';
local rateMetric = metricsCatalog.rateMetric;
local combined = metricsCatalog.combined;

// Combined component definitions are a specialisation of the service-component.
// They allow multiple components to be combined under a single name, but with different
// static labels.
//
// This allows different components to be specific for different stages (for example). This
// is specifically useful for loadbalancers
local combinedServiceLevelIndicatorDefinition(
  userImpacting,
  components,
  featureCategory,
  description,
  team=null,
  serviceAggregation=false,
  staticLabels={},
  ignoreTrafficCessation=false,
      ) =
  {
    initServiceLevelIndicatorWithName(componentName)::
      // TODO: validate that all staticLabels are unique
      local componentsInitialised = std.map(function(c) c.initServiceLevelIndicatorWithName(componentName), components);

      {
        name: componentName,
        userImpacting: userImpacting,
        featureCategory: featureCategory,
        description: description,
        team: team,
        ignoreTrafficCessation: ignoreTrafficCessation,

        serviceAggregation: serviceAggregation,

        // Returns true if this component allows detailed breakdowns
        // this is not the case for combined component definitions
        supportsDetails(): false,

        hasApdex():: componentsInitialised[0].hasApdex(),
        hasRequestRate():: componentsInitialised[0].hasRequestRate(),
        hasAggregatableRequestRate():: componentsInitialised[0].hasAggregatableRequestRate(),
        hasErrorRate():: componentsInitialised[0].hasErrorRate(),

        hasToolingLinks()::
          std.length(self.getToolingLinks()) > 0,

        getToolingLinks()::
          std.flatMap(function(c) c.getToolingLinks(), componentsInitialised),

        // Generate recording rules for apdex weight
        generateApdexWeightRecordingRules(burnRate, recordingRuleName, aggregationLabels, recordingRuleStaticLabels)::
          std.flatMap(function(c) c.generateApdexWeightRecordingRules(burnRate, recordingRuleName, aggregationLabels, recordingRuleStaticLabels), componentsInitialised),

        // Generate recording rules for apdex score
        generateApdexScoreRecordingRules(burnRate, recordingRuleName, aggregationLabels, recordingRuleStaticLabels, substituteWeightWithRecordingRuleName)::
          std.flatMap(function(c) c.generateApdexScoreRecordingRules(burnRate, recordingRuleName, aggregationLabels, recordingRuleStaticLabels, substituteWeightWithRecordingRuleName), componentsInitialised),

        // Generate recording rules for request rate
        generateRequestRateRecordingRules(burnRate, recordingRuleName, aggregationLabels, recordingRuleStaticLabels)::
          std.flatMap(function(c) c.generateRequestRateRecordingRules(burnRate, recordingRuleName, aggregationLabels, recordingRuleStaticLabels), componentsInitialised),

        // Generate recording rules for error rate
        generateErrorRateRecordingRules(burnRate, recordingRuleName, aggregationLabels, recordingRuleStaticLabels)::
          std.flatMap(function(c) c.generateErrorRateRecordingRules(burnRate, recordingRuleName, aggregationLabels, recordingRuleStaticLabels), componentsInitialised),

        // Significant labels are the union of all significantLabels from the components
        significantLabels:
          std.set(std.flatMap(function(c) c.significantLabels, componentsInitialised)),
      },
  };

{
  combinedServiceLevelIndicatorDefinition:: combinedServiceLevelIndicatorDefinition,
}
