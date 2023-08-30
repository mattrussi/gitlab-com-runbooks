local basic = import 'grafana/basic.libsonnet';

local runnersManagerMatching = import './runner_managers_matching.libsonnet';

local workerFeedRate(partition=runnersManagerMatching.defaultPartition) =
  basic.timeseries(
    'Worker feed rate',
    legendFormat='{{shard}}',
    format='ops',
    query=runnersManagerMatching.formatQuery(|||
      sum by(shard) (
        increase(
          gitlab_runner_worker_feeds_total{environment=~"$environment", stage=~"$stage", %(runnerManagersMatcher)s}[$__rate_interval]
        )
      )
    |||, partition),
  );

local workerFeedFailuresRate(partition=runnersManagerMatching.defaultPartition) =
  basic.timeseries(
    'Worker feed failures rate',
    legendFormat='{{shard}}',
    format='ops',
    query=runnersManagerMatching.formatQuery(|||
      sum by(shard) (
        increase(
          gitlab_runner_worker_feed_failures_total{environment=~"$environment", stage=~"$stage", %(runnerManagersMatcher)s}[$__rate_interval]
        )
      )
    |||, partition),
  );

local workerSlots(partition=runnersManagerMatching.defaultPartition) =
  basic.timeseries(
    'Worker slots',
    legendFormat='{{shard}}',
    format='short',
    query=runnersManagerMatching.formatQuery(|||
      sum by(shard) (
        gitlab_runner_worker_slots_number{environment=~"$environment", stage=~"$stage", %(runnerManagersMatcher)s}
      )
    |||, partition),
  );

local workerSlotOperationsRate(partition=runnersManagerMatching.defaultPartition) =
  basic.timeseries(
    'Worker slot operations rate',
    legendFormat='{{shard}}',
    format='ops',
    query=runnersManagerMatching.formatQuery(|||
      sum by(shard) (
        increase(
          gitlab_runner_worker_slot_operations_total{environment=~"$environment", stage=~"$stage", %(runnerManagersMatcher)s}[$__rate_interval]
        )
      )
    |||, partition),
  );

local workerProcessingFailuresRate(partition=runnersManagerMatching.defaultPartition) =
  basic.timeseries(
    'Worker processing failures rate',
    legendFormat='{{shard}}: {{failure_type}}',
    format='ops',
    query=runnersManagerMatching.formatQuery(|||
      sum by(shard, failure_type) (
        increase(
          gitlab_runner_worker_processing_failures_total{environment=~"$environment", stage=~"$stage", %(runnerManagersMatcher)s}[$__rate_interval]
        )
      )
    |||, partition),
  );

local workerHealthCheckFailuresRate(partition=runnersManagerMatching.defaultPartition) =
  basic.timeseries(
    'Worker health check failures rate',
    legendFormat='{{shard}}: {{runner_name}}',
    format='ops',
    query=runnersManagerMatching.formatQuery(|||
      sum by(shard, runner_name) (
        increase(
          gitlab_runner_worker_health_check_failures_total{environment=~"$environment", stage=~"$stage", %(runnerManagersMatcher)s}[$__rate_interval]
        )
      )
    |||, partition),
  );

{
  workerFeedRate: workerFeedRate,
  workerFeedFailuresRate: workerFeedFailuresRate,
  workerSlots: workerSlots,
  workerSlotOperationsRate: workerSlotOperationsRate,
  workerProcessingFailuresRate: workerProcessingFailuresRate,
  workerHealthCheckFailuresRate: workerHealthCheckFailuresRate,
}
