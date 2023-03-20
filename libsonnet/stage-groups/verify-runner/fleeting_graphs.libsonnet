local panels = import './panels.libsonnet';
local basic = import 'grafana/basic.libsonnet';

local provisionerInstancesSaturation =
  basic.timeseries(
    'Fleeting instances saturation',
    legendFormat='{{shard}}',
    format='percentunit',
    query=|||
      sum by(shard) (
          fleeting_provisioner_instances{state=~"running|deleting", environment=~"$environment", stage=~"$stage", instance=~"${runner_manager:pipe}"}
      )
      /
      sum by(shard) (
          fleeting_provisioner_max_instances{environment=~"$environment", stage=~"$stage", instance=~"${runner_manager:pipe}"}
      )
    |||,
  );

local provisionerInstancesStates =
  basic.timeseries(
    'Fleeting instances states',
    legendFormat='{{shard}}: {{state}}',
    format='short',
    query=|||
      sum by(shard, state) (
        fleeting_provisioner_instances{environment=~"$environment", stage=~"$stage", instance=~"${runner_manager:pipe}"}
      )
    |||,
  );

local provisionerMissedUpdates =
  basic.timeseries(
    'Fleeting missed updates rate',
    legendFormat='{{shard}}',
    format='short',
    query=|||
      sum by(shard) (
        increase(
          fleeting_provisioner_missed_updates_total{environment=~"$environment", stage=~"$stage", instance=~"${runner_manager:pipe}"}[$__interval]
        )
      )
    |||,
  );

local provisionerInstanceOperationsRate =
  basic.timeseries(
    'Fleeting instance operations rate',
    legendFormat='{{shard}}: {{operation}}',
    format='short',
    query=|||
      sum by(shard, operation) (
        increase(
          fleeting_provisioner_instance_operations_total{environment=~"$environment", stage=~"$stage", instance=~"${runner_manager:pipe}"}[$__interval]
        )
      )
    |||,
  );

local provisionerCreationTiming =
  panels.heatmap(
    'Fleeting instance creation timing',
    |||
      sum by (le) (
        increase(fleeting_provisioner_instance_creation_time_seconds_bucket{environment=~"$environment", stage=~"$stage", instance=~"${runner_manager:pipe}"}[$__interval])
      )
    |||,
    color_cardColor='#00DD33',
    color_exponent=0.1,
    intervalFactor=2,
  );

local provisionerIsRunningTiming =
  panels.heatmap(
    'Fleeting instance is_running timing',
    |||
      sum by (le) (
        increase(fleeting_provisioner_instance_is_running_time_seconds_bucket{environment=~"$environment", stage=~"$stage", instance=~"${runner_manager:pipe}"}[$__interval])
      )
    |||,
    color_cardColor='#DDDD00',
    color_exponent=0.1,
    intervalFactor=2,
  );

local provisionerDeletionTiming =
  panels.heatmap(
    'Fleeting instance deletion timing',
    |||
      sum by (le) (
        increase(fleeting_provisioner_instance_deletion_time_seconds_bucket{environment=~"$environment", stage=~"$stage", instance=~"${runner_manager:pipe}"}[$__interval])
      )
    |||,
    color_cardColor='#DD0000',
    color_exponent=0.1,
    intervalFactor=2,
  );

local provisionerInstanceLifeDuration =
  panels.heatmap(
    'Fleeting instance life duration',
    |||
      sum by (le) (
        increase(fleeting_provisioner_instance_life_duration_seconds_bucket{environment=~"$environment", stage=~"$stage", instance=~"${runner_manager:pipe}"}[$__interval])
      )
    |||,
    color_cardColor='#3333DD',
    color_exponent=0.1,
    intervalFactor=2,
  );

local taskscalerTasksSaturation =
  basic.timeseries(
    'Taskscaler tasks saturation',
    legendFormat='{{shard}}',
    format='percentunit',
    query=|||
      sum by(shard) (
          fleeting_taskscaler_tasks{environment=~"$environment", stage=~"$stage", instance=~"${runner_manager:pipe}", state!~"idle|reserved"}
      )
      /
      sum by(shard) (
                fleeting_provisioner_max_instances{environment=~"$environment", stage=~"$stage", instance=~"${runner_manager:pipe}"}
                *
                fleeting_taskscaler_max_tasks_per_instance{environment=~"$environment", stage=~"$stage", instance=~"${runner_manager:pipe}"}
      )
    |||,
  );

local taskscalerOperationsRate =
  basic.timeseries(
    'Taskscaler operations rate',
    legendFormat='{{shard}}: {{operation}}',
    format='short',
    query=|||
      sum by(shard, operation) (
        increase(
          fleeting_taskscaler_task_operations_total{environment=~"$environment", stage=~"$stage", instance=~"${runner_manager:pipe}"}[$__interval]
        )
      )
    |||,
  );

local taskscalerTasks =
  basic.timeseries(
    'Taskscaler tasks',
    legendFormat='{{shard}}: {{state}}',
    format='short',
    query=|||
      sum by(shard, state) (
          fleeting_taskscaler_tasks{environment=~"$environment", stage=~"$stage", instance=~"${runner_manager:pipe}"}
      )
    |||,
  );

local taskscalerInstanceReadinessTiming =
  panels.heatmap(
    'Taskscaler instance readiness timing',
    |||
      sum by (le) (
        increase(fleeting_taskscaler_task_instance_readiness_time_seconds_bucket{environment=~"$environment", stage=~"$stage", instance=~"${runner_manager:pipe}"}[$__interval])
      )
    |||,
    color_cardColor='#DD33DD',
    color_exponent=0.1,
    intervalFactor=2,
  );

local taskscalerScaleOperationsRate =
  basic.timeseries(
    'Taskscaler scale operations rate',
    legendFormat='{{shard}}: {{operation}}',
    format='short',
    query=|||
      sum by(shard, operation) (
        increase(
          fleeting_taskscaler_scale_operations_total{environment=~"$environment", stage=~"$stage", instance=~"${runner_manager:pipe}"}[$__interval]
        )
      )
    |||,
  );

{
  provisionerInstancesSaturation: provisionerInstancesSaturation,
  provisionerInstancesStates: provisionerInstancesStates,
  provisionerMissedUpdates: provisionerMissedUpdates,
  provisionerInstanceOperationsRate: provisionerInstanceOperationsRate,
  provisionerCreationTiming: provisionerCreationTiming,
  provisionerIsRunningTiming: provisionerIsRunningTiming,
  provisionerDeletionTiming: provisionerDeletionTiming,
  provisionerInstanceLifeDuration: provisionerInstanceLifeDuration,
  taskscalerTasksSaturation: taskscalerTasksSaturation,
  taskscalerOperationsRate: taskscalerOperationsRate,
  taskscalerTasks: taskscalerTasks,
  taskscalerInstanceReadinessTiming: taskscalerInstanceReadinessTiming,
  taskscalerScaleOperationsRate: taskscalerScaleOperationsRate,
}
