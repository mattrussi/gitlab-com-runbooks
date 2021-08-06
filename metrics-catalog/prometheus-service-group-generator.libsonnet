local aggregationSets = import './aggregation-sets.libsonnet';
local recordingRuleRegistry = import './recording-rule-registry.libsonnet';
local recordingRules = import 'recording-rules/recording-rules.libsonnet';
local intervalForDuration = import 'servicemetrics/interval-for-duration.libsonnet';

local recordingRuleGroupsForServiceForBurnRate(serviceDefinition, burnRate) =
  local rulesetGenerators =
    (
      if serviceDefinition.type != 'registry' then
        [
          recordingRules.sliRecordingRulesSetGenerator(burnRate, recordingRuleRegistry),
          recordingRules.componentMetricsRuleSetGenerator(
            burnRate=burnRate,
            aggregationSet=aggregationSets.promSourceSLIs
          ),
          recordingRules.extraRecordingRuleSetGenerator(burnRate),
        ]
      else
        // registry needs to include an extra label for migration_path during the migration
        // so we use an extra source aggregation set for it
        [
          recordingRules.sliRecordingRulesSetGenerator(burnRate, recordingRuleRegistry),
          recordingRules.componentMetricsRuleSetGenerator(
            burnRate=burnRate,
            aggregationSet=aggregationSets.registryMigrationSourceSLIs
          ),
          recordingRules.extraRecordingRuleSetGenerator(burnRate),
        ]
    )
    +
    (
      if serviceDefinition.nodeLevelMonitoring then
        [
          recordingRules.componentMetricsRuleSetGenerator(
            burnRate=burnRate,
            aggregationSet=aggregationSets.promSourceNodeAggregatedSLIs,
          ),
        ]
      else
        []
    );

  {
    name: 'Component-Level SLIs: %s - %s burn-rate' % [serviceDefinition.type, burnRate],  // TODO: rename to "Prometheus Intermediate Metrics"
    interval: intervalForDuration.intervalForDuration(burnRate),
    rules:
      std.flatMap(
        function(r) r.generateRecordingRulesForService(serviceDefinition),
        rulesetGenerators
      ),
  };

local featureCategoryRecordingRuleGroupsForService(serviceDefinition, burnRate) =
  local generator = recordingRules.componentMetricsRuleSetGenerator(burnRate, aggregationSets.featureCategorySourceSLIs);
  local indicators = std.filter(function(indicator) indicator.hasFeatureCategory(), serviceDefinition.listServiceLevelIndicators());
  {
    name: 'Prometheus Intermediate Metrics per feature: %s - burn-rate %s' % [serviceDefinition.type, burnRate],
    rules: generator.generateRecordingRulesForService(serviceDefinition, serviceLevelIndicators=indicators),
  };
{
  /**
   * Generate all source recording rule groups for a specific service.
   * These are the first level aggregation, for normalizing source metrics
   * into a consistent format
   */
  recordingRuleGroupsForService(serviceDefinition)::
    local componentMappingRuleSetGenerator = recordingRules.componentMappingRuleSetGenerator();
    local componentNodeSLORuleSetGenerator = recordingRules.componentNodeSLORuleSetGenerator();

    local burnRates = aggregationSets.promSourceSLIs.getBurnRates();

    [
      recordingRuleGroupsForServiceForBurnRate(serviceDefinition, burnRate)
      for burnRate in burnRates
    ]
    +
    // Component mappings are static recording rules which help
    // determine whether a component is being monitored. This helps
    // prevent spurious alerts when a component is decommissioned.
    [{
      name: 'Component mapping: %s' % [serviceDefinition.type],
      interval: '1m',  // TODO: we could probably extend this out to 5m
      rules:
        componentMappingRuleSetGenerator.generateRecordingRulesForService(serviceDefinition)
        +
        componentNodeSLORuleSetGenerator.generateRecordingRulesForService(serviceDefinition),
    }],
  featureCategoryRecordingRuleGroupsForService(serviceDefinition)::
    [
      featureCategoryRecordingRuleGroupsForService(serviceDefinition, burnRate)
      for burnRate in aggregationSets.featureCategorySourceSLIs.getBurnRates()
    ],

}
