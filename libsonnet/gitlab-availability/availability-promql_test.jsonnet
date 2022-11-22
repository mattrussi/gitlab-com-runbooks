local availabilityPromql = import './availability-promql.libsonnet';
local aggregationSet = import 'servicemetrics/aggregation-set.libsonnet';
local test = import 'test.libsonnet';

test.suite({
  local keyServices = ['webservice', 'registry'],
  local testSet = aggregationSet.AggregationSet({
    id: 'service',
    name: 'Global Service-Aggregated Metrics',
    intermediateSource: false,  // Used in dashboards and alerts
    selector: { monitor: 'global' },
    labels: ['env', 'environment', 'type', 'stage'],
    metricFormats: {
      apdexSuccessRate: 'gitlab_service_apdex:success:rate_%s',
      apdexWeight: 'gitlab_service_apdex:weight:score_%s',
      opsRate: 'gitlab_service_ops:rate_%s',
      errorRate: 'gitlab_service_errors:rate_%s',
    },
  }),

  local testPromql = availabilityPromql.new(keyServices, testSet),

  testSuccessRate: {
    actual: testPromql.successRate,
    expect: |||
      (
        sum by(env,environment,type,stage) (
          gitlab_service_apdex:success:rate_1h{type=~"registry|webservice"}
        )
        +
        sum by (env,environment,type,stage)(
          gitlab_service_ops:rate_1h{type=~"registry|webservice"} - gitlab_service_errors:rate_1h{type=~"registry|webservice"}
        )
      )
    |||,
  },

  testOpsRate: {
    actual: testPromql.opsRate,
    expect: |||
      (
        sum by(env,environment,type,stage) (
          gitlab_service_ops:rate_1h{type=~"registry|webservice"}
        )
        +
        sum by (env,environment,type,stage) (
          gitlab_service_apdex:weight:score_1h{type=~"registry|webservice"}
        )
      )
    |||,
  },

  testRateRules: {
    actual: std.map(function(rule) rule.record, testPromql.rateRules),
    expect: ['gitlab:availability:ops:rate_1h', 'gitlab:availability:success:rate_1h'],
  },
})
