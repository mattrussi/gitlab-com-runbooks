local services = (import 'gitlab-metrics-config.libsonnet').monitoredServices;
local aggregationSets = (import 'gitlab-metrics-config.libsonnet').aggregationSets;
local prometheusServiceGroupGenerator = import 'servicemetrics/prometheus-service-group-generator.libsonnet';

local outputPromYaml(groups) =
  std.manifestYamlDoc({
    groups: groups,
  });

local featureCategoryFileForService(service) =
  if service.hasFeatureCategorySLIs() then
    {
      ['feature-category-metrics-%s.yml' % [service.type]]:
        outputPromYaml(
          prometheusServiceGroupGenerator.featureCategoryRecordingRuleGroupsForService(
            service,
            aggregationSet=aggregationSets.featureCategorySourceSLIs,
          )
        ),
    }
  else {};

local filesForService(service) =
  {
    ['key-metrics-%s.yml' % [service.type]]:
      outputPromYaml(
        prometheusServiceGroupGenerator.recordingRuleGroupsForService(
          service,
          componentAggregationSet=aggregationSets.promSourceSLIs,
          nodeAggregationSet=aggregationSets.promSourceNodeComponentSLIs,
          shardAggregationSet=aggregationSets.promSourceShardComponentSLIs
        )
      ),
  } + featureCategoryFileForService(service);

/**
 * The source SLI recording rules are each kept in their own files, generated from this
 */
local prometheusEvaluatedServices = std.filter(function(service) !service.dangerouslyThanosEvaluated, services);

std.foldl(function(memo, service) memo + filesForService(service), prometheusEvaluatedServices, {})
