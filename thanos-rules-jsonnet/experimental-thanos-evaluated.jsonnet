local services = (import 'gitlab-metrics-config.libsonnet').monitoredServices;

local filesForServices = (import 'recording-rules/service-key-metrics-rule-files.libsonnet').filesForServices;

local aggregationSets = (import 'gitlab-metrics-config.libsonnet').aggregationSets;

filesForServices(
  services=std.filter(function(service)
                        std.member(['web'], service.type),
                      services),
  componentAggregationSet=aggregationSets.experimentalComponentSLIs,
  nodeAggregationSet=null,
  featureCategoryAggregationSet=aggregationSets.experimentalFeatureCategorySLIs,  //todo
  shardAggregationSet=null,
  filenamePrefix='experimental-'
)
