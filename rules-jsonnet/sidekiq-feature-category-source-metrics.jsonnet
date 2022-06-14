local sidekiqPerWorkerRecordingRules = import '../metrics-catalog/services/lib/sidekiq-per-worker-recording-rules.libsonnet';
local aggregationSets = (import 'gitlab-metrics-config.libsonnet').aggregationSets;
{
  'feature-category-metrics-sidekiq.yml': std.manifestYamlDoc({
    groups: [{
      name: 'Prometheus Intermediate Metrics per feature',
      interval: '1m',
      rules: sidekiqPerWorkerRecordingRules.perWorkerRecordingRulesForAggregationSet(aggregationSets.featureCategorySourceSLIs, { component: 'sidekiq_execution' }),
    }],
  }),
}
