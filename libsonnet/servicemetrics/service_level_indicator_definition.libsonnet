local aggregations = import 'promql/aggregations.libsonnet';
local selectors = import 'promql/selectors.libsonnet';
local transactionalRates = import 'recording-rules/transactional-rates/transactional-rates.libsonnet';
local stages = import 'service-catalog/stages.libsonnet';
local dependencies = import 'servicemetrics/dependencies_definition.libsonnet';
local metricsCatalog = import 'servicemetrics/metrics-catalog.libsonnet';
local descriptor = import 'servicemetrics/sli_metric_descriptor.libsonnet';
local toolingLinks = import 'toolinglinks/toolinglinks.libsonnet';
local strings = import 'utils/strings.libsonnet';
local filterLabelsFromLabelsHash = (import 'promql/labels.libsonnet').filterLabelsFromLabelsHash;

local featureCategoryFromSourceMetrics = 'featureCategoryFromSourceMetrics';

/*
Given the reference architecture does not record metrics per group, the stage groups mapping will be empty:
https://gitlab.com/gitlab-com/runbooks/-/blob/master/reference-architectures/get-hybrid/src/gitlab-metrics-config.libsonnet#L64

Not owned category key should be kept hardcoded here for this reason.
*/
local featureCategoryNotOwned = 'not_owned';

// For now we assume that services are provisioned on vms and not kubernetes
// Please consult the README.md file for details of team and feature_category
local serviceLevelIndicatorDefaults = {
  featureCategory: featureCategoryNotOwned,
  team: null,
  description: '',
  staticLabels+: {},  // by default, no static labels
  serviceAggregation: true,  // by default, requestRate is aggregated up to the service level
  trafficCessationAlertConfig: true,  // Override to false to disable alerting when SLI is zero or absent
  upscaleLongerBurnRates: false,  // When true, long-term burn rates will be upscaled from shorter burn rates, to optimize for high cardinality metrics
  severity: 's2',
  dependsOn: [],  // When an sli depends on another component, don't alert on this SLI if the downstream service is already firing. This is meant for hard dependencies managed by GitLab.
  shardLevelMonitoring: false,
  emittedBy: [],  // Which services emit the metrics for this SLI, e.g. rails_redis_client SLI is emitted by web service

  useConfidenceLevelForSLIAlerts: null,  // Use confidence intervals when alerting on SLIs. These have better performance in low RPS situations.
};

local validateHasField(object, field, message) =
  if std.objectHas(object, field) then
    object
  else
    std.assertEqual(true, { __assert: message });

local validateFeatureCategory(object, sliName) =
  if std.objectHas(stages.featureCategoryMap, object.featureCategory) then
    object
  else if object.featureCategory == featureCategoryFromSourceMetrics then
    assert std.member(object.significantLabels, 'feature_category') : 'feature_category needs to be a significant label for %s' % [sliName];
    object
  else if object.featureCategory == featureCategoryNotOwned then
    object
  else
    assert false : 'feature category: %s is not a valid category for %s' % [object.featureCategory, sliName];
    {};

local validateSeverity(object, message) =
  if std.objectHas(object, 'severity') && std.member(['s1', 's2', 's3', 's4'], object.severity) then
    object
  else
    std.assertEqual(true, { __assert: message });

local validateAndApplySLIDefaults(sliName, component, inheritedDefaults) =
  local withDefaults = serviceLevelIndicatorDefaults
                       { emittedBy: [inheritedDefaults.type] } +
                       inheritedDefaults +
                       component +
                       { dependencies: dependencies.new(withDefaults.type, sliName, withDefaults.dependsOn) };

  // All components must have a requestRate measurement, since
  // we filter out low-RPS alerts for apdex monitoring and require the RPS for error ratios
  validateHasField(withDefaults, 'requestRate', '%s component requires a requestRate measurement' % [sliName])
  +
  validateHasField(withDefaults, 'significantLabels', '%s component requires a significantLabels attribute' % [sliName])
  +
  validateHasField(withDefaults, 'userImpacting', '%s component requires a userImpacting attribute' % [sliName])
  +
  validateFeatureCategory(withDefaults, '%s is not a valid feature category for %s' % [withDefaults.featureCategory, sliName])
  +
  validateSeverity(withDefaults, '%s does not have a valid severity, must be s1-s4' % [sliName])
  +
  validateFeatureCategory(withDefaults, sliName)
  {
    name: sliName,
  };

// Currently, we use 1h metrics for upscaling source
local getUpscaleLabels(sli, burnRate) =
  if sli.upscaleLongerBurnRates && burnRate == '1h' then
    { upscale_source: 'yes' }
  else
    {};

// Currently we only do upscaling on 6h burn rates
local isUpscalingTarget(sli, burnRate) =
  sli.upscaleLongerBurnRates && burnRate == '6h';

// validate type selector against emittedBy
local validateTypeSelector(sliDefinition) =
  local metricDescriptor = descriptor.sliMetricsDescriptor([sliDefinition]);
  local selectorsByMetric = metricDescriptor.selectorsByMetric;
  local emittingTypesByMetric = metricDescriptor.emittingTypesByMetric;

  if selectorsByMetric != {} then
    local v = std.foldl(
      function(_, metricName)
        local selector = selectorsByMetric[metricName];
        local emittingTypes = emittingTypesByMetric[metricName];
        local typeSelector = std.get(selector, 'type');

        if typeSelector != null && std.length(emittingTypes) > 0 then
          local selectedTypes = if std.objectHas(typeSelector, 'oneOf') then std.set(typeSelector.oneOf) else [typeSelector];
          assert std.set(emittingTypes) == std.set(selectedTypes) :
                 'Service %s SLI %s metric %s is emitted by %s but is selected from type %s. Ensure emittedBy and type selector has the same values.' % [
            sliDefinition.type,
            sliDefinition.name,
            metricName,
            emittingTypes,
            selectedTypes,
          ];
          {}
        else {},
      std.objectFields(selectorsByMetric),
      {},
    );
    sliDefinition + v  // hack to force validation to run. v is an empty object
  else
    sliDefinition;

local postDefinitionValidators = [
  validateTypeSelector,
];

local validatePostDefinition(sliDefinition) =
  std.foldl(
    function(_, validator) validator(sliDefinition),
    postDefinitionValidators,
    sliDefinition,
  );

// Definition of a service level indicator
local serviceLevelIndicatorDefinition(sliName, serviceLevelIndicator) =
  validatePostDefinition(serviceLevelIndicator {
    // Returns true if this serviceLevelIndicator allows detailed breakdowns
    // this is not the case for combined serviceLevelIndicator definitions
    supportsDetails(): true,

    hasApdexSLO():: std.objectHas(self, 'monitoringThresholds') &&
                    std.objectHas(self.monitoringThresholds, 'apdexScore'),
    hasApdex():: std.objectHas(serviceLevelIndicator, 'apdex'),
    hasHistogramApdex()::
      // Only apdex SLIs using a histogram can generate a histogram_quantile graph
      // in alerts
      self.hasApdex() &&
      std.objectHasAll(serviceLevelIndicator.apdex, 'histogram'),

    hasRequestRate():: true,  // requestRate is mandatory
    hasAggregatableRequestRate():: std.objectHasAll(serviceLevelIndicator.requestRate, 'aggregatedRateQuery'),
    hasErrorRateSLO()::
      std.objectHas(serviceLevelIndicator, 'monitoringThresholds') &&
      std.objectHas(serviceLevelIndicator.monitoringThresholds, 'errorRatio'),
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

    hasFeatureCategoryFromSourceMetrics()::
      std.objectHas(serviceLevelIndicator, 'featureCategory') &&
      serviceLevelIndicator.featureCategory == featureCategoryFromSourceMetrics,

    hasStaticFeatureCategory()::
      std.objectHas(serviceLevelIndicator, 'featureCategory') &&
      serviceLevelIndicator.featureCategory != featureCategoryNotOwned &&
      !self.hasFeatureCategoryFromSourceMetrics(),

    hasFeatureCategory()::
      self.hasStaticFeatureCategory() || self.hasFeatureCategoryFromSourceMetrics(),

    hasDependencies()::
      std.length(self.dependsOn) > 0,

    staticFeatureCategoryLabels()::
      if self.hasStaticFeatureCategory() then
        { feature_category: serviceLevelIndicator.featureCategory }
      else
        {},

    hasDashboardFeatureCategories()::
      std.objectHas(serviceLevelIndicator, 'dashboardFeatureCategories') &&
      std.length(serviceLevelIndicator.dashboardFeatureCategories) > 0,

    opsRateMetrics: self.requestRate.metricNames,
    errorRateMetrics: if self.hasErrorRate() then self.errorRate.metricNames else [],
    apdexMetrics: if self.hasApdex() then self.apdex.metricNames else [],
    metricNames:
      std.set(self.opsRateMetrics + self.errorRateMetrics + self.apdexMetrics),

    // Returns true if this SLI should use confidence levels in alert evaulation.
    usesConfidenceLevelForSLIAlerts()::
      self.useConfidenceLevelForSLIAlerts != null,

    // Returns the confidence interval level used on this SLI.
    // Using a method here allows this logic to be reconfigured in future
    // to configure opt-out rather than opt-in on confidence levels.
    getConfidenceLevel()::
      self.useConfidenceLevelForSLIAlerts,

    // Generate recording rules for apdex
    generateApdexRecordingRules(burnRate, aggregationSet, recordingRuleStaticLabels, selector={}, config={})::
      if self.hasApdex() && !isUpscalingTarget(self, burnRate) then
        local apdexMetric = serviceLevelIndicator.apdex { config+: config };
        local upscaleLabels = getUpscaleLabels(self, burnRate);
        local allStaticLabels = recordingRuleStaticLabels + serviceLevelIndicator.staticLabels + upscaleLabels;
        local aggregationLabelsWithoutStaticLabels = filterLabelsFromLabelsHash(aggregationSet.labels, allStaticLabels);

        local apdexSuccessRateRecordingRuleName = aggregationSet.getApdexSuccessRateMetricForBurnRate(burnRate);
        local apdexWeightRecordingRuleName = aggregationSet.getApdexWeightMetricForBurnRate(burnRate);
        local apdexRatesMetric = aggregationSet.getApdexRatesMetricForBurnRate(burnRate);

        local apdexSuccessRateExpr = apdexMetric.apdexSuccessRateQuery(
          aggregationLabels=aggregationLabelsWithoutStaticLabels,
          selector=selector,
          rangeInterval=burnRate,
          offset=aggregationSet.offset,
        );

        local apdexWeightExpr = apdexMetric.apdexWeightQuery(
          aggregationLabels=aggregationLabelsWithoutStaticLabels,
          selector=selector,
          rangeInterval=burnRate,
          offset=aggregationSet.offset,
        );

        local apdexRatesExpr = transactionalRates.apdexRatesExpr(apdexSuccessRateExpr, apdexWeightExpr);

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
        +
        (
          if apdexRatesMetric != null then
            [{
              record: apdexRatesMetric,
              labels: allStaticLabels,
              expr: apdexRatesExpr,
            }]
          else
            []
        )
      else
        [],

    // Generate recording rules for request rate
    generateRequestRateRecordingRules(burnRate, aggregationSet, recordingRuleStaticLabels, selector={}, config={})::
      if !isUpscalingTarget(self, burnRate) then
        local requestRateMetric = serviceLevelIndicator.requestRate { config+: config };
        local upscaleLabels = getUpscaleLabels(self, burnRate);
        local requestRateRecordingRuleName = aggregationSet.getOpsRateMetricForBurnRate(burnRate, required=true);
        local allStaticLabels = recordingRuleStaticLabels + serviceLevelIndicator.staticLabels + upscaleLabels;

        [{
          record: requestRateRecordingRuleName,
          labels: allStaticLabels,
          expr: requestRateMetric.aggregatedRateQuery(
            aggregationLabels=filterLabelsFromLabelsHash(aggregationSet.labels, allStaticLabels),
            selector=selector,
            rangeInterval=burnRate,
            offset=aggregationSet.offset,
          ),
        }]
      else
        [],

    // Generate recording rules for error rate
    generateErrorRateRecordingRules(burnRate, aggregationSet, recordingRuleStaticLabels, selector={}, config={})::
      if self.hasErrorRate() && !isUpscalingTarget(self, burnRate) then
        local errorRateMetric = serviceLevelIndicator.errorRate { config+: config };
        local opsRateMetric = serviceLevelIndicator.requestRate { config+: config };
        local upscaleLabels = getUpscaleLabels(self, burnRate);
        local allStaticLabels = recordingRuleStaticLabels + serviceLevelIndicator.staticLabels + upscaleLabels;
        local requestRateRecordingRuleName = aggregationSet.getOpsRateMetricForBurnRate(burnRate, required=true);
        local errorRateRecordingRuleName = aggregationSet.getErrorRateMetricForBurnRate(burnRate, required=true);
        local filteredAggregationLabels = filterLabelsFromLabelsHash(aggregationSet.labels, allStaticLabels);

        local errorRateExpr = errorRateMetric.aggregatedRateQuery(
          aggregationLabels=filterLabelsFromLabelsHash(aggregationSet.labels, allStaticLabels),
          selector=selector,
          rangeInterval=burnRate,
          offset=aggregationSet.offset,
        );

        local opsRateExpr = opsRateMetric.aggregatedRateQuery(
          aggregationLabels=filterLabelsFromLabelsHash(aggregationSet.labels, allStaticLabels),
          selector=selector,
          rangeInterval=burnRate,
          offset=aggregationSet.offset,
        );

        local errorRatesMetric = aggregationSet.getErrorRatesMetricForBurnRate(burnRate);

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
            expr: strings.indent(errorRateExpr, 2),
            filteredAggregationLabels: aggregations.serialize(filteredAggregationLabels),
            requestRateRecordingRuleName: requestRateRecordingRuleName,
            allStaticLabels: selectors.serializeHash(selectors.merge(selector, allStaticLabels)),
          },
        }]
        +
        (
          if errorRatesMetric != null then
            [{
              record: errorRatesMetric,
              labels: allStaticLabels,
              expr: transactionalRates.errorRatesExpr(errorRateExpr, opsRateExpr),
            }]
          else
            []
        )
      else
        [],
  });

{
  serviceLevelIndicatorDefinition(serviceLevelIndicator)::
    {
      initServiceLevelIndicatorWithName(sliName, inheritedDefaults)::
        serviceLevelIndicatorDefinition(sliName, validateAndApplySLIDefaults(sliName, serviceLevelIndicator, inheritedDefaults)),
    },
  featureCategoryFromSourceMetrics: featureCategoryFromSourceMetrics,
  featureCategoryNotOwned: featureCategoryNotOwned,
}
