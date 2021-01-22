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
      name: aggregationSets.globalSLIs.name,
      interval: '1m',
      partial_response_strategy: 'warn',
      rules: aggregationSetTransformer.generateRecordingRules(
        sourceAggregationSet=aggregationSets.promSourceSLIs,
        targetAggregationSet=aggregationSets.globalSLIs
      ),
    }]),

  /**
   * Aggregates from multiple "split-brain" prometheus SLIs to a global/single-view service-level aggregated metrics
   */
  'aggregated-service-metrics.yml':
    outputPromYaml(
      [{
        name: aggregationSets.serviceAggregatedSLIs.name,
        interval: '1m',
        partial_response_strategy: 'warn',
        rules: aggregationSetTransformer.generateRecordingRules(
          sourceAggregationSet=aggregationSets.promSourceSLIs,
          targetAggregationSet=aggregationSets.serviceAggregatedSLIs
        ),
      }]
    ),

  /**
   * Aggregates from multiple "split-brain" prometheus per-node SLIs to a global/single-view SLI-node-level aggregated metrics
   */
  'aggregated-sli-node-metrics.yml':
    outputPromYaml(
      [{
        name: aggregationSets.globalNodeSLIs.name,
        interval: '1m',
        partial_response_strategy: 'warn',
        rules: aggregationSetTransformer.generateRecordingRules(
          sourceAggregationSet=aggregationSets.promSourceNodeAggregatedSLIs,
          targetAggregationSet=aggregationSets.globalNodeSLIs
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
        name: aggregationSets.serviceNodeAggregatedSLIs.name,
        interval: '1m',
        partial_response_strategy: 'warn',
        rules: aggregationSetTransformer.generateRecordingRules(
          sourceAggregationSet=aggregationSets.globalNodeSLIs,
          targetAggregationSet=aggregationSets.serviceNodeAggregatedSLIs
        ),
      }]
    ),
}
