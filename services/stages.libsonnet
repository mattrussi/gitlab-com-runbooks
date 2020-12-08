local stageGroupMapping = import 'stage-group-mapping.jsonnet';

/* This is a special pseudo-stage group for the feature_category of `not_owned` */
local notOwnedGroup = {
  name: 'not_owned',
  stage: 'not_owned',
  feature_categories: [
    'not_owned',
  ],
};

/**
 * Constructs a map of [featureCategory]stageGroup for featureCategory lookups
 */
local stageGroupMappingLookup = std.foldl(
  function(map, stageGroupName)
    local stageGroup = stageGroupMapping[stageGroupName];
    std.foldl(
      function(map, featureCategory)
        map {
          [featureCategory]: stageGroup,
        },
      stageGroup.feature_categories,
      map
    ),
  std.objectFields(stageGroupMapping),
  {
    [notOwnedGroup.feature_categories[0]]: notOwnedGroup,
  }
);

local findStageGroupForFeatureCategory(featureCategory) =
  stageGroupMappingLookup[featureCategory];

local findStageGroupNameForFeatureCategory(featureCategory) =
  findStageGroupForFeatureCategory(featureCategory).name;

local findStageNameForFeatureCategory(featureCategory) =
  findStageGroupForFeatureCategory(featureCategory).stage;

local stageGroup(groupName) =
  stageGroupMapping[groupName];

local categoriesForStageGroup(groupName) =
  stageGroup(groupName).feature_categories;

{
  /**
   * Given a feature category, returns the appropriate stage group
   */
  findStageGroupForFeatureCategory:: findStageGroupForFeatureCategory,

  /**
   * Given a feature category, returns the appropriate stage group name
   * will return `not_owned` for `not_owned` feature category
   */
  findStageGroupNameForFeatureCategory:: findStageGroupNameForFeatureCategory,

  /**
   * Given a feature category, returns the appropriate stage name
   * will return `not_owned` for `not_owned` feature category
   */
  findStageNameForFeatureCategory:: findStageNameForFeatureCategory,

  /**
   * Given a stage-group name will return an array of feature categories
   * Will result in an error if an unknown group name is passed
   */
  categoriesForStageGroup(groupName):: categoriesForStageGroup(groupName),

  /**
   * Given a stage-group name will return the stage group object
   * Will result in an error if an unknown group name is passed
   */
  stageGroup(groupName):: stageGroup(groupName),
}
