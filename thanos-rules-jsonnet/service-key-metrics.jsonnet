local services = (import 'gitlab-metrics-config.libsonnet').monitoredServices;
local aggregationSets = (import 'gitlab-metrics-config.libsonnet').aggregationSets;
local prometheusServiceGroupGenerator = import 'servicemetrics/prometheus-service-group-generator.libsonnet';

// This file is similar to rules-jsonnet/service-key-metrics.jsonnet
// but focuses only on services with dangerouslyThanosEvaluated=true

local outputPromYaml(groups) =
  std.manifestYamlDoc({
    groups: [
      group { partial_response_strategy: 'warn' }
      for group in groups
    ],
  });

local filesForService(service) =
  {
    ['key-metrics-%s.yml' % [service.type]]:
      outputPromYaml(
        prometheusServiceGroupGenerator.recordingRuleGroupsForService(
          service,
          componentAggregationSet=aggregationSets.promSourceSLIs,
          nodeAggregationSet=aggregationSets.promSourceNodeComponentSLIs,
        )
      ),
  };

/**
 * The source SLI recording rules are each kept in their own files, generated from this
 */
local dangerouslyThanosEvaluatedServices = std.filter(function(service) service.dangerouslyThanosEvaluated, services);

std.foldl(function(memo, service) memo + filesForService(service), dangerouslyThanosEvaluatedServices, {})
