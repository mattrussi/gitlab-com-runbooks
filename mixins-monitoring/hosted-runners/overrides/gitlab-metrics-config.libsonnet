local referenceArchitecturesGitLabConfig = import 'runbooks/reference-architectures/get-hybrid/src/gitlab-metrics-config.libsonnet';
local aggregationSets = import 'reference-aggregation-sets.libsonnet';
local aggregationSet = import 'servicemetrics/aggregation-set.libsonnet';
local labelSet = (import 'label-taxonomy/label-set.libsonnet');
local options = import 'gitlab-metrics-options.libsonnet';

# TODO: add this to the metrics
local shardComponentSLIs = aggregationSet.AggregationSet({
    id: 'component_shard',
    name: 'Global Shard-Aggregated SLI Metrics',
    intermediateSource: false,
    selector: {},
    labels: ['type', 'component', 'shard'],
    supportedBurnRates: ['5m', '30m', '1h', '6h'],
    metricFormats: {
      apdexSuccessRate: 'gitlab_component_shard_apdex:success:rate_%s',
      apdexWeight: 'gitlab_component_shard_apdex:weight:score_%s',
      apdexRatio: 'gitlab_component_shard_apdex:ratio_%s',
      opsRate: 'gitlab_component_shard_ops:rate_%s',
      errorRate: 'gitlab_component_shard_errors:rate_%s',
      errorRatio: 'gitlab_component_shard_errors:ratio_%s',

      // Confidence Interval Ratios
      apdexConfidenceRatio: 'gitlab_component_shard_apdex:confidence:ratio_%s',
      errorConfidenceRatio: 'gitlab_component_shard_errors:confidence:ratio_%s',
    },
  });

referenceArchitecturesGitLabConfig + {
  monitoredServices: [
     import '../lib/service.libsonnet'
  ],

  saturationMonitoring+: import '../lib/saturation.libsonnet',

  labelTaxonomy:: labelSet.makeLabelSet({
    environmentThanos: null,  // No thanos
    environment: null,  // Only one environment
    tier: null,  // No tiers
    service: 'type',
    stage: null,  // No stages
    shard: 'shard',
    node: null, // No node
    sliComponent: 'component',
  }),

  aggregationSets+: {
      shardComponentSLIs: shardComponentSLIs
  },
}
