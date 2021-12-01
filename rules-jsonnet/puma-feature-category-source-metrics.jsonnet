local pumaPerFeatureCategoryRules = import '../metrics-catalog/services/lib/puma-per-feature-category-recording-rules.libsonnet';
local aggregationSets = import 'aggregation-sets.libsonnet';

{
  'feature-category-metrics-puma.yml': std.manifestYamlDoc({
    groups: [{
      name: 'Prometheus Intermediate Metrics per feature',
      interval: '1m',
      rules: pumaPerFeatureCategoryRules.perFeatureCategoryRecordingRules,
    }],
  }),
}
