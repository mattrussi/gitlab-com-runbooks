local aggregationSets = (import 'gitlab-metrics-config.libsonnet').aggregationSets;
local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local rateMetric = metricsCatalog.rateMetric;

local queueRate = rateMetric(
  counter='sidekiq_enqueued_jobs_total',
  selector={},
);

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
  // Record enqueueing RPS
  perWorkerRecordingRules(rangeInterval)::
    queueRulesForBurnRate(aggregationSets.sidekiqWorkerQueueSourceSLIs, rangeInterval),
}
