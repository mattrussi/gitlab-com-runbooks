local AGGREGATION_LABELS = 'environment, tier, type, stage';

// ----------------------------------------------------------------------
// Apdex Score Rules
// ----------------------------------------------------------------------

// Checks whether a component definition includes an apdex rule
local hasApdexScore(componentDefinition) =
  std.objectHas(componentDefinition, 'apdexScoreQuery') ||
  std.objectHas(componentDefinition, 'apdexSatisfiedSeries') ||
  std.objectHas(componentDefinition, 'apdexToleratedSeries') ||
  std.objectHas(componentDefinition, 'apdexTotalSeries') ||
  std.objectHas(componentDefinition, 'apdxWeightScoreQuery');


// Generates an apdex score query for a component definition
local generateApdexScoreQuery(componentDefinition) =
  if std.objectHas(componentDefinition, 'apdexScoreQuery') then
    componentDefinition.apdexScoreQuery
  else
    |||
      (
        sum by (%(aggregationLabels)s) (rate(%(apdexSatisfiedSeries)s[1m]))
        +
        sum by (%(aggregationLabels)s) (rate(%(apdexToleratedSeries)s[1m]))
      )
      /
      2 / (sum by (%(aggregationLabels)s) (rate(%(apdexTotalSeries)s[1m])) > 0)
    ||| % {
      apdexSatisfiedSeries: componentDefinition.apdexSatisfiedSeries,
      apdexToleratedSeries: componentDefinition.apdexToleratedSeries,
      apdexTotalSeries: componentDefinition.apdexTotalSeries,
      aggregationLabels: AGGREGATION_LABELS,
    };

// Generates an apdex weight score query for a component definition
local generateApdexWeightScoreQuery(componentDefinition) =
  if std.objectHas(componentDefinition, 'apdxWeightScoreQuery') then
    componentDefinition.apdxWeightScoreQuery
  else
    |||
      sum by (%(aggregationLabels)s) (rate(%(apdexTotalSeries)s[1m]))
    ||| % {
      apdexTotalSeries: componentDefinition.apdexTotalSeries,
      aggregationLabels: AGGREGATION_LABELS,
    };

// Generates apdex score recording rules for a component definition
local generatApdexScoreRules(componentDefinition, labels) =
  if hasApdexScore(componentDefinition) then
    [
      {
        record: 'gitlab_component_apdex:ratio',
        labels: labels,
        expr: generateApdexScoreQuery(componentDefinition),
      },
      {
        record: 'gitlab_component_apdex:weight:score',
        labels: labels,
        expr: generateApdexWeightScoreQuery(componentDefinition),
      },
    ]
  else
    [];

// ----------------------------------------------------------------------
// Request Rate Rules
// ----------------------------------------------------------------------

// Checks whether a component definition includes an request rate rule
local hasRequestRateRules(componentDefinition) =
  std.objectHas(componentDefinition, 'requestRateQuery') ||
  std.objectHas(componentDefinition, 'requestRateSeries');

// Generates an request rate query for a component definition
local generateRequestRateSeriesQuery(componentDefinition) =
  if std.objectHas(componentDefinition, 'requestRateQuery') then
    componentDefinition.requestRateQuery
  else
    |||
      sum by (%(aggregationLabels)s) (rate(%(requestRateSeries)s[1m]))
    ||| % {
      requestRateSeries: componentDefinition.requestRateSeries,
      aggregationLabels: AGGREGATION_LABELS,
    };

// Generates an request rate recording rule for a component definition
local generateRequestRateRules(componentDefinition, labels) =
  if hasRequestRateRules(componentDefinition) then
    [
      {
        record: 'gitlab_component_ops:rate',
        labels: labels,
        expr: generateRequestRateSeriesQuery(componentDefinition),
      },
    ]
  else
    [];

// ----------------------------------------------------------------------
// Error Rate Rules
// ----------------------------------------------------------------------

// Checks whether a component definition includes an error rule
local hasErrorRate(componentDefinition) =
  std.objectHas(componentDefinition, 'errorRateQuery') ||
  std.objectHas(componentDefinition, 'errorRateSeries');

// Generates an error rate query for a component definition
local generateErrorRateSeriesQuery(componentDefinition) =
  if std.objectHas(componentDefinition, 'errorRateQuery') then
    componentDefinition.errorRateQuery
  else
    |||
      sum by (%(aggregationLabels)s) (rate(%(errorRateSeries)s[1m]))
    ||| % {
      errorRateSeries: componentDefinition.errorRateSeries,
      aggregationLabels: AGGREGATION_LABELS,
    };

// Generates an error rate recording rule for a component definition
local generateErrorRateRules(componentDefinition, labels) =
  if hasErrorRate(componentDefinition) then
    [
      {
        record: 'gitlab_component_errors:rate',
        labels: labels,
        expr: generateErrorRateSeriesQuery(componentDefinition),
      },
    ]
  else
    [];

{
  generateServiceSLORules(serviceDefinition)::
    std.prune([
      if std.objectHas(serviceDefinition.slos, 'apdexRatio') then
        {
          record: 'slo:min:gitlab_service_apdex:ratio',
          labels: {
            type: serviceDefinition.type,
            tier: serviceDefinition.tier,
          },
          expr: '%.4f' % [serviceDefinition.slos.apdexRatio],
        }
      else null,

      if std.objectHas(serviceDefinition.slos, 'errorRatio') then
      {
        record: 'slo:max:gitlab_service_errors:ratio',
        labels: {
          type: serviceDefinition.type,
          tier: serviceDefinition.tier,
        },
        expr: '%.4f' % [serviceDefinition.slos.errorRatio],
      },
    ]),

  generateServiceRecordingRules(serviceDefinition)::
    local components = serviceDefinition.components;

    std.flattenArrays(
      std.map(
        function(componentName) self.generateComponentRecordingRules(componentName, serviceDefinition, components[componentName]),
        std.objectFields(components)
      )
    ),

  generateComponentRecordingRules(componentName, serviceDefinition, componentDefinition)::
    local staticLabels =
      if std.objectHas(componentDefinition, 'staticLabels') then
        componentDefinition.staticLabels
      else
        {};

    local labels = {
      tier: serviceDefinition.tier,
      type: serviceDefinition.type,
      component: componentName,
    } + staticLabels;

    generatApdexScoreRules(componentDefinition, labels) +
    generateRequestRateRules(componentDefinition, labels) +
    generateErrorRateRules(componentDefinition, labels),
}
