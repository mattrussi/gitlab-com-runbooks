local sidekiqHelpers = import './sidekiq-helpers.libsonnet';
local aggregationSets = import 'aggregation-sets.libsonnet';
local metricsCatalog = import 'gitlab-monitoring/servicemetrics/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local rateMetric = metricsCatalog.rateMetric;
local combined = metricsCatalog.combined;

local executionAggregationSet = aggregationSets.sidekiqWorkerExecutionSLIs;
local aggregationLabels = executionAggregationSet.labels;

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
  local recordings =
    if std.objectHas(aggregationSet.burnRates, burnRate) then
      local recordingNames = aggregationSet.burnRates[burnRate];
      [
        if std.objectHas(recordingNames, 'apdexSuccessRate') then
          {  // Key metric: Execution apdex (ratio)
            record: recordingNames.apdexSuccessRate,
            labels: staticLabels,
            expr: combinedExecutionApdex.apdexSuccessRateQuery(aggregationSet.labels, {}, burnRate),
          }
        else {},
        if std.objectHas(recordingNames, 'apdexRatio') then
          {  // Key metric: Execution apdex (ratio)
            record: recordingNames.apdexRatio,
            labels: staticLabels,
            expr: combinedExecutionApdex.apdexQuery(aggregationSet.labels, {}, burnRate),
          }
        else {},
        {  // Key metric: Execution apdex (weight score)
          record: recordingNames.apdexWeight,
          labels: staticLabels,
          expr: combinedExecutionApdex.apdexWeightQuery(aggregationSet.labels, {}, burnRate),
        },
        {  // Key metric: QPS
          record: recordingNames.opsRate,
          labels: staticLabels,
          expr: requestRate.aggregatedRateQuery(aggregationSet.labels, {}, burnRate),
        },
        {  // Key metric: Errors per Second
          record: recordingNames.errorRate,
          labels: staticLabels,
          expr: errorRate.aggregatedRateQuery(aggregationSet.labels, {}, burnRate),
        },
        if std.objectHas(recordingNames, 'errorRatio') then
          {
            record: recordingNames.errorRatio,
            labels: staticLabels,
            expr: |||
              %(errorRate)s
              /
              %(executionRate)s
            ||| % { executionRate: recordingNames.opsRate, errorRate: recordingNames.errorRate },
          }
        else {},
      ] else [];
  std.prune(recordings);

{
  perWorkerRecordingRulesForAggregationSet(aggregationSet, staticLabels={})::
    std.flatMap(function(burnRate) executionRulesForBurnRate(aggregationSet, burnRate, staticLabels), aggregationSet.getBurnRates()),

  // Record queue apdex, execution apdex, error rates, QPS metrics
  // for each worker, similar to how we record these for each
  // service
  perWorkerRecordingRules(rangeInterval)::
    [
      {  // Key metric: Queueing apdex (ratio)
        record: 'gitlab_background_jobs:queue:apdex:ratio_%s' % [rangeInterval],
        expr: combinedQueueApdex.apdexQuery(aggregationLabels, {}, rangeInterval),
      },
      {  // Key metric: Queueing apdex (weight score)
        record: 'gitlab_background_jobs:queue:apdex:weight:score_%s' % [rangeInterval],
        expr: combinedQueueApdex.apdexWeightQuery(aggregationLabels, {}, rangeInterval),
      },
      {  // Key metric: Queueing operations/second
        record: 'gitlab_background_jobs:queue:ops:rate_%s' % [rangeInterval],
        expr: queueRate.aggregatedRateQuery(aggregationLabels, {}, rangeInterval),
      },
    ] + executionRulesForBurnRate(executionAggregationSet, rangeInterval),
}
