local aggregationSets = import 'aggregation-sets.libsonnet';
local aggregationSetTransformer = import 'servicemetrics/aggregation-set-transformer.libsonnet';
local applicationSlis = (import 'gitlab-slis/library.libsonnet').all;
local applicationSliAggregations = import 'gitlab-slis/aggregation-sets.libsonnet';

local outputPromYaml(groups) =
  std.manifestYamlDoc({
    groups: groups,
  });

local groupsForApplicationSli(sli) =
  local targetAggregationSet = applicationSliAggregations.targetAggregationSet(sli);
  local sourceAggregationSet = applicationSliAggregations.sourceAggregationSet(sli);
  {
    name: targetAggregationSet.name,
    interval: '1m',
    partial_response_strategy: 'warn',
    rules: aggregationSetTransformer.generateRecordingRules(
      sourceAggregationSet=sourceAggregationSet,
      targetAggregationSet=targetAggregationSet,
    ),
  };


/**
 * This file defines all the aggregation recording rules that will aggregate in Thanos to a single global view
 */
{
  /**
   * Aggregates from multiple "split-brain" prometheus SLIs to a global/single-view SLI metrics
   */
  'aggregated-component-metrics.yml':
    outputPromYaml([{
      name: aggregationSets.componentSLIs.name,
      interval: '1m',
      partial_response_strategy: 'warn',
      rules: aggregationSetTransformer.generateRecordingRules(
        sourceAggregationSet=aggregationSets.promSourceSLIs,
        targetAggregationSet=aggregationSets.componentSLIs
      ),
    }]),

  /**
   * Aggregates from multiple "split-brain" prometheus SLIs to a global/single-view service-level aggregated metrics
   */
  'aggregated-service-metrics.yml':
    outputPromYaml(
      [{
        name: aggregationSets.serviceSLIs.name,
        interval: '1m',
        partial_response_strategy: 'warn',
        rules: aggregationSetTransformer.generateRecordingRules(
          sourceAggregationSet=aggregationSets.promSourceSLIs,
          targetAggregationSet=aggregationSets.serviceSLIs
        ),
      }]
    ),

  /**
   * Aggregates from multiple "split-brain" prometheus per-node SLIs to a global/single-view SLI-node-level aggregated metrics
   */
  'aggregated-sli-node-metrics.yml':
    outputPromYaml(
      [{
        name: aggregationSets.nodeComponentSLIs.name,
        interval: '1m',
        partial_response_strategy: 'warn',
        rules: aggregationSetTransformer.generateRecordingRules(
          sourceAggregationSet=aggregationSets.promSourceNodeComponentSLIs,
          targetAggregationSet=aggregationSets.nodeComponentSLIs
        ),
      }]
    ),

  /**
   * Aggregates from multiple "split-brain" prometheus SLIs to a global/single-view service-node-level aggregated metrics
   * TODO: consider whether this aggregation is neccessary and useful.
   */
  'aggregated-service-node-metrics.yml':
    outputPromYaml(
      [{
        name: aggregationSets.nodeServiceSLIs.name,
        interval: '1m',
        partial_response_strategy: 'warn',
        rules: aggregationSetTransformer.generateRecordingRules(
          sourceAggregationSet=aggregationSets.promSourceNodeComponentSLIs,
          targetAggregationSet=aggregationSets.nodeServiceSLIs
        ),
      }]
    ),

  /**
   * Regional SLIS
   */
  'aggregated-sli-regional-metrics.yml':
    outputPromYaml(
      [{
        name: aggregationSets.regionalComponentSLIs.name,
        interval: '1m',
        partial_response_strategy: 'warn',
        rules: aggregationSetTransformer.generateRecordingRules(
          sourceAggregationSet=aggregationSets.promSourceSLIs,
          targetAggregationSet=aggregationSets.regionalComponentSLIs
        ),
      }]
    ),

  /**
   * Regional SLIs, aggregated to the service level
   */
  'aggregated-service-regional-metrics.yml':
    outputPromYaml(
      [{
        name: aggregationSets.nodeServiceSLIs.name,
        interval: '1m',
        partial_response_strategy: 'warn',
        rules: aggregationSetTransformer.generateRecordingRules(
          sourceAggregationSet=aggregationSets.promSourceSLIs,
          targetAggregationSet=aggregationSets.regionalServiceSLIs
        ),
      }]
    ),

  'aggregated-feature-category-metrics.yml':
    outputPromYaml(
      [{
        name: aggregationSets.featureCategorySLIs.name,
        interval: '1m',
        partial_response_strategy: 'warn',
        rules: aggregationSetTransformer.generateRecordingRules(
          sourceAggregationSet=aggregationSets.featureCategorySourceSLIs,
          targetAggregationSet=aggregationSets.featureCategorySLIs
        ),
      }]
    ),

  'aggregated-stage-group-metrics.yml':
    outputPromYaml(
      [{
        name: aggregationSets.stageGroupSLIs.name,
        interval: '1m',
        partial_response_strategy: 'warn',
        rules: aggregationSetTransformer.generateRecordingRules(
          sourceAggregationSet=aggregationSets.featureCategorySourceSLIs,
          targetAggregationSet=aggregationSets.stageGroupSLIs
        ),
      }]
    ),

  // Application SLIs not used in the service catalog  will be aggregated here.
  // These aggregations allow us to see what the metrics look like before adding
  // an them, so we can validate they would not trigger alerts.
  // If the application SLI is added to the service catalog, it will automatically
  // generate `sli_aggregation:` recordings that can be reused everywhere. So no
  // real need to duplicate them.
  'aggregated-application-sli-metrics.yml':
    outputPromYaml(
      std.filterMap(
        function(sli)
          !sli.inRecordingRuleRegistry,
        groupsForApplicationSli,
        applicationSlis
      ),
    ),
}
