local sliDefinition = import './sli-definition.libsonnet';
local test = import 'github.com/yugui/jsonnetunit/jsonnetunit/test.libsonnet';
local objects = import 'utils/objects.libsonnet';

local validSLI = {
  name: 'hello_sli',
  kind: 'apdex',
  description: 'an SLI counting hellos',
  significantLabels: ['world'],
  featureCategory: 'error_budgets',
};

test.suite({
  testNew: {
    actual: sliDefinition.new(validSLI),
    expect: {
      name: 'hello_sli',
      kind: 'apdex',
      featureCategory: 'error_budgets',
      description: 'an SLI counting hellos',
      significantLabels: ['world'],
      inRecordingRuleRegistry: false,
      totalCounterName: 'gitlab_sli:hello_sli:total',
      successCounterName: 'gitlab_sli:hello_sli:success_total',
      recordingRuleMetrics: ['gitlab_sli:hello_sli:total', 'gitlab_sli:hello_sli:success_total'],
    },
  },

  testNewWithoutFeatureCategory: {
    local sli = objects.objectWithout(validSLI, 'featureCategory') {
      significantLabels: ['world', 'feature_category'],
    },
    actual: sliDefinition.new(sli),
    expect: {
      name: 'hello_sli',
      kind: 'apdex',
      featureCategory: 'featureCategoryFromSourceMetrics',
      description: 'an SLI counting hellos',
      significantLabels: ['world', 'feature_category'],
      inRecordingRuleRegistry: false,
      totalCounterName: 'gitlab_sli:hello_sli:total',
      successCounterName: 'gitlab_sli:hello_sli:success_total',
      recordingRuleMetrics: ['gitlab_sli:hello_sli:total', 'gitlab_sli:hello_sli:success_total'],
    },
  },

  local validate(sli) = sliDefinition._sliValidator.isValid(sli),

  testFeatureCategoryUnknown: {
    local sli = validSLI { featureCategory: 'not a feature' },
    actual: validate(sli),
    expect: false,
  },

  testFeatureCategoryNotOwned: {
    local sli = validSLI { featureCategory: 'not_owned' },
    actual: validate(sli),
    expect: true,
  },

  testFeatureCategoryNull: {
    local sli = validSLI { featureCategory: null },
    actual: validate(sli),
    expect: false,
  },

  testFeatureCategoryMissing: {
    local sli = objects.objectWithout(validSLI, 'featureCategory'),
    actual: validate(sli),
    expect: false,
  },
})
