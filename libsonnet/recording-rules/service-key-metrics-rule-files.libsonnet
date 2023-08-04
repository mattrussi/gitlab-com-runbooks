local aggregationSetTransformer = import 'servicemetrics/aggregation-set-transformer.libsonnet';
local prometheusServiceGroupGenerator = import 'servicemetrics/prometheus-service-group-generator.libsonnet';

local outputPromYaml(groups, groupExtras) =
  std.manifestYamlDoc({
    groups: [
      groupExtras + group
      for group in groups
    ],
  });

local optionalReflectedRuleSet(aggregationSet, service) =
  if aggregationSet != null && aggregationSet.reflectedRatios && aggregationSet.hasRatios() then
    aggregationSetTransformer.generateReflectedRecordingRuleGroups(aggregationSet, extraSelector={ type: service.type })
  else
    [];

local filesForService(service, componentAggregationSet, nodeAggregationSet, featureCategoryAggregationSet, shardAggregationSet, groupExtras, filenamePrefix) =
  (
    if componentAggregationSet != null then
      {
        ['%skey-metrics-%s.yml' % [filenamePrefix, service.type]]:
          outputPromYaml(
            prometheusServiceGroupGenerator.recordingRuleGroupsForService(
              service,
              componentAggregationSet=componentAggregationSet,
              nodeAggregationSet=nodeAggregationSet,
              shardAggregationSet=shardAggregationSet
            ) +
            optionalReflectedRuleSet(componentAggregationSet, service) +
            optionalReflectedRuleSet(nodeAggregationSet, service) +
            optionalReflectedRuleSet(shardAggregationSet, service),
            groupExtras
          ),
      } else {}
  )
  +
  (
    if service.hasFeatureCategorySLIs() && featureCategoryAggregationSet != null then
      {
        ['%sfeature-category-metrics-%s.yml' % [filenamePrefix, service.type]]:
          outputPromYaml(
            prometheusServiceGroupGenerator.featureCategoryRecordingRuleGroupsForService(
              service,
              aggregationSet=featureCategoryAggregationSet,
            ) + optionalReflectedRuleSet(featureCategoryAggregationSet, service),
            groupExtras
          ),
      }
    else {}
  );


local filesForServices(services, componentAggregationSet, nodeAggregationSet, featureCategoryAggregationSet, shardAggregationSet, groupExtras={}, filenamePrefix='') =
  std.foldl(
    function(memo, service)
      memo + filesForService(service, componentAggregationSet, nodeAggregationSet, featureCategoryAggregationSet, shardAggregationSet, groupExtras, filenamePrefix),
    services,
    {}
  );

{
  filesForServices:: filesForServices,
}
