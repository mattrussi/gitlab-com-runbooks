local prometheusServiceGroupGenerator = import 'servicemetrics/prometheus-service-group-generator.libsonnet';

local outputPromYaml(groups, groupExtras) =
  std.manifestYamlDoc({
    groups: [
      groupExtras + group
      for group in groups
    ],
  });

local filesForService(service, componentAggregationSet, nodeAggregationSet, featureCategoryAggregationSet, groupExtras) =
  {
    ['key-metrics-%s.yml' % [service.type]]:
      outputPromYaml(
        prometheusServiceGroupGenerator.recordingRuleGroupsForService(
          service,
          componentAggregationSet=componentAggregationSet,
          nodeAggregationSet=nodeAggregationSet,
        ),
        groupExtras
      ),
  } + if service.hasFeatureCategorySLIs() then
    {
      ['feature-category-metrics-%s.yml' % [service.type]]:
        outputPromYaml(
          prometheusServiceGroupGenerator.featureCategoryRecordingRuleGroupsForService(
            service,
            aggregationSet=featureCategoryAggregationSet,
          ),
          groupExtras
        ),
    }
  else {};


local filesForServices(services, componentAggregationSet, nodeAggregationSet, featureCategoryAggregationSet, groupExtras={}) =
  std.foldl(
    function(memo, service)
      memo + filesForService(service, componentAggregationSet, nodeAggregationSet, featureCategoryAggregationSet, groupExtras),
    services,
    {}
  );

{
  filesForServices:: filesForServices,
}
