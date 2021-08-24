local aggregationSets = import 'aggregation-sets.libsonnet';
local aggregationSetTransformer = import 'servicemetrics/aggregation-set-transformer.libsonnet';

local outputPromYaml(groups) =
  std.manifestYamlDoc({
    groups: groups,
  });

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
          sourceAggregationSet=aggregationSets.featureCategorySLIs,
          targetAggregationSet=aggregationSets.stageGroupSLIs
        ),
      }]
    ),

}
