local sidekiqHelpers = import './sidekiq-helpers.libsonnet';
local aggregationSets = (import 'gitlab-metrics-config.libsonnet').aggregationSets;
local aggregations = import 'promql/aggregations.libsonnet';
local selectors = import 'promql/selectors.libsonnet';
local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local strings = import 'utils/strings.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local rateMetric = metricsCatalog.rateMetric;
local combined = metricsCatalog.combined;

local queueRate = rateMetric(
  counter='sidekiq_enqueued_jobs_total',
  selector={},
);

local requestRate = rateMetric(
  counter='sidekiq_jobs_completion_seconds_bucket',
  selector={ le: '+Inf' },
);

local executionRulesForBurnRate(aggregationSet, burnRate, staticLabels={}) =
  local aggregationLabelsWithoutStaticLabels = std.filter(
    function(label)
      !std.objectHas(staticLabels, label),
    aggregationSet.labels
  );

  local conditionalAppend(record, expr) =
    if record == null then []
    else
      [{
        record: record,
        [if staticLabels != {} then 'labels']: staticLabels,
        expr: expr,
      }];

  // Key metric: QPS
  conditionalAppend(
    record=aggregationSet.getOpsRateMetricForBurnRate(burnRate, required=false),
    expr=requestRate.aggregatedRateQuery(aggregationLabelsWithoutStaticLabels, {}, burnRate)
  )
;

local queueRulesForBurnRate(aggregationSet, burnRate, staticLabels={}) =
  local conditionalAppend(record, expr) =
    if record == null then []
    else
      [{
        record: record,
        expr: expr,
      }];

  // Key metric: Queueing operations/second
  conditionalAppend(
    record=aggregationSet.getOpsRateMetricForBurnRate(burnRate, required=false),
    expr=queueRate.aggregatedRateQuery(aggregationSet.labels, staticLabels, burnRate)
  );

{
  // Record enqueueing RPS and job execution RPS
  perWorkerRecordingRules(rangeInterval)::
    queueRulesForBurnRate(aggregationSets.sidekiqWorkerQueueSourceSLIs, rangeInterval)
    +
    executionRulesForBurnRate(aggregationSets.sidekiqWorkerExecutionSourceSLIs, rangeInterval),
}
