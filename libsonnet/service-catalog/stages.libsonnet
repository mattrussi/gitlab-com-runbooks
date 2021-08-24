// stage-group-mapping.jsonnet is generated file, stored in the `services` directory
local stageGroupMapping = import 'stage-group-mapping.jsonnet';

/* This is a special pseudo-stage group for the feature_category of `not_owned` */
local notOwnedGroup = {
  key: 'not_owned',
  name: 'not_owned',
  stage: 'not_owned',
  feature_categories: [
    'not_owned',
  ],
};

local stageGroup(groupName) =
  stageGroupMapping[groupName] { key: groupName };

local stageGroups =
  std.map(stageGroup, std.objectFields(stageGroupMapping)) + [notOwnedGroup];

/**
 * Constructs a map of [featureCategory]stageGroup for featureCategory lookups
 */
local stageGroupMappingLookup = std.foldl(
  function(map, stageGroup)
    std.foldl(
      function(map, featureCategory)
        map {
          [featureCategory]: stageGroup,
        },
      stageGroup.feature_categories,
      map
    ),
  stageGroups,
  {}
);

local findStageGroupForFeatureCategory(featureCategory) =
  stageGroupMappingLookup[featureCategory];

local findStageGroupNameForFeatureCategory(featureCategory) =
  findStageGroupForFeatureCategory(featureCategory).name;

local findStageNameForFeatureCategory(featureCategory) =
  findStageGroupForFeatureCategory(featureCategory).stage;

local categoriesForStageGroup(groupName) =
  stageGroup(groupName).feature_categories;

local groupsForStage(stageName) = std.filter(
  function(stageGroupElement)
    stageGroupElement.stage == stageName,
  stageGroups
);

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

  /**
   * Returns a map of featureCategory[stageGroup]
   **/
  featureCategoryMap:: stageGroupMappingLookup,

  /**
   * Returns the not owned group
   */
  notOwned:: notOwnedGroup,

  /**
   * Return all the groups of a stage
   */
  groupsForStage: groupsForStage,
}
