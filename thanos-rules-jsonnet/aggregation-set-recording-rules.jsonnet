local services = import './services/all.jsonnet';
local configMap = import 'recording-rule-config-map.libsonnet';

local outputPromYaml(groups) =
  std.manifestYamlDoc({
    groups: groups,
  });

// Select all services with `autogenerateRecordingRules` (default on)
local selectedServices = std.filter(function(service) service.autogenerateRecordingRules, services);

{
  /**
   * Aggregates from multiple "split-brain" prometheus SLIs to a global/single-view SLI metrics
   */
  'aggregated-component-metrics.yml':
    outputPromYaml([{
      name: 'Autogenerated Component Metrics',
      interval: '1m',
      partial_response_strategy: 'warn',
      rules: configMap.thanos.componentAggregation.generateRecordingRules(),
    }]),

  /**
   * Aggregates from multiple "split-brain" prometheus SLIs to a global/single-view service-level aggregated metrics
   */
  'aggregated-service-metrics.yml':
    outputPromYaml([{
      name: 'Autogenerated Service Metrics',
      interval: '1m',
      partial_response_strategy: 'warn',
      rules: configMap.thanos.serviceAggregation.generateRecordingRules(),
    }]),

  /**
   * Aggregates from multiple "split-brain" prometheus SLIs to node-SLI metrics
   */
  'aggregated-sli-node-metrics.yml':
    outputPromYaml([{
      name: 'Autogenerated Component-Node Metrics',
      interval: '1m',
      partial_response_strategy: 'warn',
      rules: configMap.thanos.componentNodeAggregation.generateRecordingRules(),
    }]),

  /**
   * Aggregates from multiple "split-brain" prometheus SLIs to a global/single-view service-node-level aggregated metrics
   * TODO: consider whether this aggregation is neccessary and useful.
   */
  'aggregated-service-node-metrics.yml':
    outputPromYaml([{
      name: 'Autogenerated Service-Node Metrics',
      interval: '1m',
      partial_response_strategy: 'warn',
      rules: configMap.thanos.serviceNodeAggregation.generateRecordingRules(),
    }]),
}
