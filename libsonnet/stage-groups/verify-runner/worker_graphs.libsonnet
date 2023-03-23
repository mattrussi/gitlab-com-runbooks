local basic = import 'grafana/basic.libsonnet';

local workerFeedRate =
  basic.timeseries(
    'Worker feed rate',
    legendFormat='{{shard}}',
    format='ops',
    query=|||
      sum by(shard) (
        increase(
          gitlab_runner_worker_feeds_total{environment=~"$environment", stage=~"$stage", instance=~"${runner_manager:pipe}"}[$__rate_interval]
        )
      )
    |||,
  );

local workerFeedFailuresRate =
  basic.timeseries(
    'Worker feed failures rate',
    legendFormat='{{shard}}',
    format='ops',
    query=|||
      sum by(shard) (
        increase(
          gitlab_runner_worker_feed_failures_total{environment=~"$environment", stage=~"$stage", instance=~"${runner_manager:pipe}"}[$__rate_interval]
        )
      )
    |||,
  );

local workerSlots =
  basic.timeseries(
    'Worker slots',
    legendFormat='{{shard}}',
    format='short',
    query=|||
      sum by(shard) (
        gitlab_runner_worker_slots_number{environment=~"$environment", stage=~"$stage", instance=~"${runner_manager:pipe}"}
      )
    |||,
  );

local workerSlotOperationsRate =
  basic.timeseries(
    'Worker slot operations rate',
    legendFormat='{{shard}}',
    format='ops',
    query=|||
      sum by(shard) (
        increase(
          gitlab_runner_worker_slot_operations_total{environment=~"$environment", stage=~"$stage", instance=~"${runner_manager:pipe}"}[$__rate_interval]
        )
      )
    |||,
  );

local workerProcessingFailuresRate =
  basic.timeseries(
    'Worker processing failures rate',
    legendFormat='{{shard}}: {{failure_type}}',
    format='ops',
    query=|||
      sum by(shard, failure_type) (
        increase(
          gitlab_runner_worker_processing_failures_total{environment=~"$environment", stage=~"$stage", instance=~"${runner_manager:pipe}"}[$__rate_interval]
        )
      )
    |||,
  );

local workerHealthCheckFailuresRate =
  basic.timeseries(
    'Worker health check failures rate',
    legendFormat='{{shard}}: {{runner_name}}',
    format='ops',
    query=|||
      sum by(shard, runner_name) (
        increase(
          gitlab_runner_worker_health_check_failures_total{environment=~"$environment", stage=~"$stage", instance=~"${runner_manager:pipe}"}[$__rate_interval]
        )
      )
    |||,
  );

{
  workerFeedRate: workerFeedRate,
  workerFeedFailuresRate: workerFeedFailuresRate,
  workerSlots: workerSlots,
  workerSlotOperationsRate: workerSlotOperationsRate,
  workerProcessingFailuresRate: workerProcessingFailuresRate,
  workerHealthCheckFailuresRate: workerHealthCheckFailuresRate,
}
