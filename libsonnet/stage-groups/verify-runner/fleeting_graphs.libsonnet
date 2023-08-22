local panels = import './panels.libsonnet';
local basic = import 'grafana/basic.libsonnet';

local runnersManagerMatching = import './runner_managers_matching.libsonnet';

local provisionerInstancesSaturation(partition=runnersManagerMatching.defaultPartition) =
  basic.timeseries(
    'Fleeting instances saturation',
    legendFormat='{{shard}}',
    format='percentunit',
    query=runnersManagerMatching.formatQuery(|||
      sum by(shard) (
        fleeting_provisioner_instances{state=~"running|deleting", environment=~"$environment", stage=~"$stage", %(runnerManagersMatcher)s}
      )
      /
      sum by(shard) (
        fleeting_provisioner_max_instances{environment=~"$environment", stage=~"$stage", %(runnerManagersMatcher)s}
      )
    |||, partition),
  );

local provisionerInstancesStates(partition=runnersManagerMatching.defaultPartition) =
  basic.timeseries(
    'Fleeting instances states',
    legendFormat='{{shard}}: {{state}}',
    format='short',
    query=runnersManagerMatching.formatQuery(|||
      sum by(shard, state) (
        fleeting_provisioner_instances{environment=~"$environment", stage=~"$stage", %(runnerManagersMatcher)s}
      )
    |||, partition),
  );

local provisionerMissedUpdates(partition=runnersManagerMatching.defaultPartition) =
  basic.timeseries(
    'Fleeting missed updates rate',
    legendFormat='{{shard}}',
    format='ops',
    query=runnersManagerMatching.formatQuery(|||
      sum by(shard) (
        rate(
          fleeting_provisioner_missed_updates_total{environment=~"$environment", stage=~"$stage", %(runnerManagersMatcher)s}[$__rate_interval]
        )
      )
    |||, partition),
  );

local provisionerInstanceOperationsRate(partition=runnersManagerMatching.defaultPartition) =
  basic.timeseries(
    'Fleeting instance operations rate',
    legendFormat='{{shard}}: {{operation}}',
    format='ops',
    query=runnersManagerMatching.formatQuery(|||
      sum by(shard, operation) (
        rate(
          fleeting_provisioner_instance_operations_total{environment=~"$environment", stage=~"$stage", %(runnerManagersMatcher)s}[$__rate_interval]
        )
      )
    |||, partition),
  );

local provisionerInternalOperationsRate(partition=runnersManagerMatching.defaultPartition) =
  basic.timeseries(
    'Fleeting internal operations rate',
    legendFormat='{{shard}}: {{operation}}',
    format='ops',
    query=runnersManagerMatching.formatQuery(|||
      sum by(shard, operation) (
        rate(
          fleeting_provisioner_internal_operations_total{environment=~"$environment", stage=~"$stage", %(runnerManagersMatcher)s}[$__rate_interval]
        )
      )
    |||, partition),
  );

local provisionerCreationTiming(partition=runnersManagerMatching.defaultPartition) =
  panels.heatmap(
    'Fleeting instance creation timing',
    runnersManagerMatching.formatQuery(|||
      sum by (le) (
        rate(
          fleeting_provisioner_instance_creation_time_seconds_bucket{environment=~"$environment", stage=~"$stage", %(runnerManagersMatcher)s}[$__rate_interval]
        )
      )
    |||, partition),
    color_mode='spectrum',
    color_colorScheme='Greens',
    legend_show=true,
    intervalFactor=2,
  );

local provisionerIsRunningTiming(partition=runnersManagerMatching.defaultPartition) =
  panels.heatmap(
    'Fleeting instance is_running timing',
    runnersManagerMatching.formatQuery(|||
      sum by (le) (
        rate(
          fleeting_provisioner_instance_is_running_time_seconds_bucket{environment=~"$environment", stage=~"$stage", %(runnerManagersMatcher)s}[$__rate_interval]
        )
      )
    |||, partition),
    color_mode='spectrum',
    color_colorScheme='Blues',
    legend_show=true,
    intervalFactor=2,
  );

local provisionerDeletionTiming(partition=runnersManagerMatching.defaultPartition) =
  panels.heatmap(
    'Fleeting instance deletion timing',
    runnersManagerMatching.formatQuery(|||
      sum by (le) (
        rate(
          fleeting_provisioner_instance_deletion_time_seconds_bucket{environment=~"$environment", stage=~"$stage", %(runnerManagersMatcher)s}[$__rate_interval]
        )
      )
    |||, partition),
    color_mode='spectrum',
    color_colorScheme='Reds',
    legend_show=true,
    intervalFactor=2,
  );

local provisionerInstanceLifeDuration(partition=runnersManagerMatching.defaultPartition) =
  panels.heatmap(
    'Fleeting instance life duration',
    runnersManagerMatching.formatQuery(|||
      sum by (le) (
        rate(
          fleeting_provisioner_instance_life_duration_seconds_bucket{environment=~"$environment", stage=~"$stage", %(runnerManagersMatcher)s}[$__rate_interval]
        )
      )
    |||, partition),
    color_mode='spectrum',
    color_colorScheme='Purples',
    legend_show=true,
    intervalFactor=2,
  );

local taskscalerTasksSaturation(partition=runnersManagerMatching.defaultPartition) =
  basic.timeseries(
    'Taskscaler tasks saturation',
    legendFormat='{{shard}}',
    format='percentunit',
    query=runnersManagerMatching.formatQuery(|||
      sum by(shard) (
        fleeting_taskscaler_tasks{environment=~"$environment", stage=~"$stage", %(runnerManagersMatcher)s, state!~"idle|reserved"}
      )
      /
      sum by(shard) (
        fleeting_provisioner_max_instances{environment=~"$environment", stage=~"$stage", %(runnerManagersMatcher)s}
        *
        fleeting_taskscaler_max_tasks_per_instance{environment=~"$environment", stage=~"$stage", %(runnerManagersMatcher)s}
      )
    |||, partition),
  );

local taskscalerMaxUseCountPerInstance(partition=runnersManagerMatching.defaultPartition) =
  basic.timeseries(
    'Taskscaler max use count per instance',
    legendFormat='{{shard}}',
    format='short',
    query=runnersManagerMatching.formatQuery(|||
      sum by(shard) (
        fleeting_taskscaler_max_use_count_per_instance{environment=~"$environment", stage=~"$stage", %(runnerManagersMatcher)s}
      )
    |||, partition),
  );

local taskscalerOperationsRate(partition=runnersManagerMatching.defaultPartition) =
  basic.timeseries(
    'Taskscaler operations rate',
    legendFormat='{{shard}}: {{operation}}',
    format='ops',
    query=runnersManagerMatching.formatQuery(|||
      sum by(shard, operation) (
        rate(
          fleeting_taskscaler_task_operations_total{environment=~"$environment", stage=~"$stage", %(runnerManagersMatcher)s}[$__rate_interval]
        )
      )
    |||, partition),
  );

local taskscalerTasks(partition=runnersManagerMatching.defaultPartition) =
  basic.timeseries(
    'Taskscaler tasks',
    legendFormat='{{shard}}: {{state}}',
    format='short',
    query=runnersManagerMatching.formatQuery(|||
      sum by(shard, state) (
        fleeting_taskscaler_tasks{environment=~"$environment", stage=~"$stage", %(runnerManagersMatcher)s}
      )
    |||, partition),
  );

local taskscalerInstanceReadinessTiming(partition=runnersManagerMatching.defaultPartition) =
  panels.heatmap(
    'Taskscaler instance readiness timing',
    runnersManagerMatching.formatQuery(|||
      sum by (le) (
        rate(
          fleeting_taskscaler_task_instance_readiness_time_seconds_bucket{environment=~"$environment", stage=~"$stage", %(runnerManagersMatcher)s}[$__rate_interval]
        )
      )
    |||, partition),
    color_mode='spectrum',
    color_colorScheme='Oranges',
    legend_show=true,
    intervalFactor=2,
  );

local taskscalerScaleOperationsRate(partition=runnersManagerMatching.defaultPartition) =
  basic.timeseries(
    'Taskscaler scale operations rate',
    legendFormat='{{shard}}: {{operation}}',
    format='ops',
    query=runnersManagerMatching.formatQuery(|||
      sum by(shard, operation) (
        rate(
          fleeting_taskscaler_scale_operations_total{environment=~"$environment", stage=~"$stage", %(runnerManagersMatcher)s}[$__rate_interval]
        )
      )
    |||, partition),
  );

local taskscalerDesiredInstances(partition=runnersManagerMatching.defaultPartition) =
  basic.timeseries(
    'Taskscaler desired instances',
    legendFormat='{{shard}}',
    format='short',
    query=runnersManagerMatching.formatQuery(|||
      sum by(shard) (
        fleeting_taskscaler_desired_instances{environment=~"$environment", stage=~"$stage", %(runnerManagersMatcher)s}
      )
    |||, partition),
  );

{
  provisionerInstancesSaturation:: provisionerInstancesSaturation,
  provisionerInstancesStates:: provisionerInstancesStates,
  provisionerMissedUpdates:: provisionerMissedUpdates,
  provisionerInstanceOperationsRate:: provisionerInstanceOperationsRate,
  provisionerInternalOperationsRate:: provisionerInternalOperationsRate,
  provisionerCreationTiming:: provisionerCreationTiming,
  provisionerIsRunningTiming:: provisionerIsRunningTiming,
  provisionerDeletionTiming:: provisionerDeletionTiming,
  provisionerInstanceLifeDuration:: provisionerInstanceLifeDuration,
  taskscalerTasksSaturation:: taskscalerTasksSaturation,
  taskscalerMaxUseCountPerInstance:: taskscalerMaxUseCountPerInstance,
  taskscalerOperationsRate:: taskscalerOperationsRate,
  taskscalerTasks:: taskscalerTasks,
  taskscalerDesiredInstances:: taskscalerDesiredInstances,
  taskscalerInstanceReadinessTiming:: taskscalerInstanceReadinessTiming,
  taskscalerScaleOperationsRate:: taskscalerScaleOperationsRate,
}
