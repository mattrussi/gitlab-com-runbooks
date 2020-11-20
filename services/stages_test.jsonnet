local test = import 'github.com/yugui/jsonnetunit/jsonnetunit/test.libsonnet';
local stages = import 'stages.libsonnet';

test.suite({
  testBlank: {
    actual: stages.findStageGroupForFeatureCategory('users').name,
    expect: 'Access',
  },
  testNotOwnedStageGroupForFeatureCategory: {
    actual: stages.findStageGroupForFeatureCategory('not_owned').name,
    expect: 'not_owned',
  },
  testNotOwnedStageGroupNameForFeatureCategory: {
    actual: stages.findStageGroupNameForFeatureCategory('not_owned'),
    expect: 'not_owned',
  },
  testNotOwnedStageNameForFeatureCategory: {
    actual: stages.findStageNameForFeatureCategory('not_owned'),
    expect: 'not_owned',
  },

})
