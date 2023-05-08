local stages = import 'service-catalog/stages.libsonnet';
local objects = import 'utils/objects.libsonnet';
local crossoverMappings = objects.invert((import 'gitlab-metrics-config.libsonnet').stageGroupMappingCrossover);

local rules = std.flatMap(
  function(featureCategory)
    local stageGroup = stages.featureCategoryMap[featureCategory];
    local featureCategories = [featureCategory] + std.flattenArrays(
      [  // TODO: this inner array can be removed as soon as the PR
        // https://github.com/google/jsonnet/pull/1082 is merged,
        // and a new version of jsonnet is released
        std.prune([std.get(crossoverMappings, featureCategory)]),
      ]
    );

    std.map(
      function(category)
        {
          record: 'gitlab:feature_category:stage_group:mapping',
          labels: {
            feature_category: category,
            stage_group: stageGroup.key,
            product_stage: stageGroup.stage,
          },
          expr: '1',
        },
      featureCategories,
    ),
  std.objectFields(stages.featureCategoryMap)
);

{
  mappingYaml(extrasForGroup={}): {
    'stage-group-feature-category-mapping-rules.yml': std.manifestYamlDoc({
      groups: [{
        name: 'Feature Category Stage group mapping',
        rules: rules,
        interval: '1m',
      } + extrasForGroup],
    }),
  },
}
