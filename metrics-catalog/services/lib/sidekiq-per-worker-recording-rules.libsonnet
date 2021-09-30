local sidekiqHelpers = import './sidekiq-helpers.libsonnet';
local aggregationSets = import 'aggregation-sets.libsonnet';
local aggregations = import 'promql/aggregations.libsonnet';
local selectors = import 'promql/selectors.libsonnet';
local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local strings = import 'utils/strings.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local rateMetric = metricsCatalog.rateMetric;
local combined = metricsCatalog.combined;


// This is used to calculate the queue apdex across all queues
local combinedQueueApdex = combined([
  histogramApdex(
    histogram='sidekiq_jobs_queue_duration_seconds_bucket',
    selector={ urgency: 'high' },
    satisfiedThreshold=sidekiqHelpers.slos.urgent.queueingDurationSeconds,
  ),
  histogramApdex(
    histogram='sidekiq_jobs_queue_duration_seconds_bucket',
    selector={ urgency: 'low' },
    satisfiedThreshold=sidekiqHelpers.slos.lowUrgency.queueingDurationSeconds,
  ),
]);

local combinedExecutionApdex = combined([
  histogramApdex(
    histogram='sidekiq_jobs_completion_seconds_bucket',
    selector={ urgency: 'high' },
    satisfiedThreshold=sidekiqHelpers.slos.urgent.executionDurationSeconds,
  ),
  histogramApdex(
    histogram='sidekiq_jobs_completion_seconds_bucket',
    selector={ urgency: 'low' },
    satisfiedThreshold=sidekiqHelpers.slos.lowUrgency.executionDurationSeconds,
  ),
  histogramApdex(
    histogram='sidekiq_jobs_completion_seconds_bucket',
    selector={ urgency: 'throttled' },
    satisfiedThreshold=sidekiqHelpers.slos.throttled.executionDurationSeconds,
  ),
]);

local queueRate = rateMetric(
  counter='sidekiq_enqueued_jobs_total',
  selector={},
);

local requestRate = rateMetric(
  counter='sidekiq_jobs_completion_seconds_bucket',
  selector={ le: '+Inf' },
);

local errorRate = rateMetric(
  counter='sidekiq_jobs_failed_total',
  selector={},
);

local executionRulesForBurnRate(aggregationSet, burnRate, staticLabels={}) =
  local conditionalAppend(record, expr) =
    if record == null then []
    else
      [{
        record: record,
        [if staticLabels != {} then 'labels']: staticLabels,
        expr: expr,
      }];

  // Key metric: Execution apdex (ratio)
  conditionalAppend(
    record=aggregationSet.getApdexSuccessRateMetricForBurnRate(burnRate, required=false),
    expr=combinedExecutionApdex.apdexSuccessRateQuery(aggregationSet.labels, {}, burnRate)
  )
  +
  // Key metric: Execution apdex (ratio)
  // TODO: we can probably DELETE THIS after the Sidekiq metrics work is complete
  conditionalAppend(
    record=aggregationSet.getApdexRatioMetricForBurnRate(burnRate, required=false),
    expr=combinedExecutionApdex.apdexQuery(aggregationSet.labels, {}, burnRate)
  )
  +
  // Key metric: Execution apdex (weight score)
  conditionalAppend(
    record=aggregationSet.getApdexWeightMetricForBurnRate(burnRate, required=false),
    expr=combinedExecutionApdex.apdexWeightQuery(aggregationSet.labels, {}, burnRate),
  )
  +
  // Key metric: QPS
  conditionalAppend(
    record=aggregationSet.getOpsRateMetricForBurnRate(burnRate, required=false),
    expr=requestRate.aggregatedRateQuery(aggregationSet.labels, {}, burnRate)
  )
  +
  // Key metric: Errors per Second
  conditionalAppend(
    record=aggregationSet.getErrorRateMetricForBurnRate(burnRate, required=false),
    expr=|||
      %(errorRate)s
      or
      (
        0 * group by (%(aggregationLabels)s) (
          %(executionRate)s{%(staticLabels)s}
        )
      )
    ||| % {
      errorRate: strings.chomp(errorRate.aggregatedRateQuery(aggregationSet.labels, {}, burnRate)),
      aggregationLabels: aggregations.serialize(aggregationSet.labels),
      executionRate: aggregationSet.getOpsRateMetricForBurnRate(burnRate, required=true),
      staticLabels: selectors.serializeHash(staticLabels),
    }
  )
  +
  // Key metric: Error Ratio
  // TODO: we can probably DELETE THIS after the Sidekiq metrics work is complete
  conditionalAppend(
    record=aggregationSet.getErrorRatioMetricForBurnRate(burnRate, required=false),
    expr=|||
      %(errorRate)s
      /
      %(executionRate)s
    ||| % {
      errorRate: aggregationSet.getErrorRateMetricForBurnRate(burnRate, required=true),
      executionRate: aggregationSet.getOpsRateMetricForBurnRate(burnRate, required=true),
    },
  );

local queueRulesForBurnRate(aggregationSet, burnRate, staticLabels={}) =
  local conditionalAppend(record, expr) =
    if record == null then []
    else
      [{
        record: record,
        expr: expr,
      }];

  // Key metric: Queueing apdex (ratio)
  conditionalAppend(
    record=aggregationSet.getApdexRatioMetricForBurnRate(burnRate, required=false),
    expr=combinedQueueApdex.apdexQuery(aggregationSet.labels, staticLabels, burnRate)
  )
  +
  // Key metric: Queueing apdex (weight score)
  conditionalAppend(
    record=aggregationSet.getApdexWeightMetricForBurnRate(burnRate, required=false),
    expr=combinedQueueApdex.apdexWeightQuery(aggregationSet.labels, staticLabels, burnRate)
  )
  +
  // Key metric: Queueing operations/second
  conditionalAppend(
    record=aggregationSet.getOpsRateMetricForBurnRate(burnRate, required=false),
    expr=queueRate.aggregatedRateQuery(aggregationSet.labels, staticLabels, burnRate)
  );

{
  perWorkerRecordingRulesForAggregationSet(aggregationSet, staticLabels={})::
    std.flatMap(function(burnRate) executionRulesForBurnRate(aggregationSet, burnRate, staticLabels), aggregationSet.getBurnRates()),

  // Record queue apdex, execution apdex, error rates, QPS metrics
  // for each worker, similar to how we record these for each
  // service
  perWorkerRecordingRules(rangeInterval)::
    queueRulesForBurnRate(aggregationSets.sidekiqWorkerQueueSLIs, rangeInterval)
    +
    executionRulesForBurnRate(aggregationSets.sidekiqWorkerExecutionSLIs, rangeInterval),
}
