local panels = import './panels.libsonnet';
local basic = import 'grafana/basic.libsonnet';

local provisionerMaxInstances =
  basic.statPanel(
    title=null,
    panelTitle='Fleeting max instances',
    color='green',
    query='sum by(shard) (fleeting_provisioner_max_instances{environment=~"$environment",stage=~"$stage",instance=~"${runner_manager:pipe}"})',
    legendFormat='{{shard}}',
    unit='short',
    decimals=0,
    colorMode='value',
    instant=true,
    interval='1d',
    intervalFactor=1,
    reducerFunction='last',
    justifyMode='center',
  );

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
    fill=1,
    stack=true,
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
    fill=1,
    stack=true,
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
    color_cardColor='#96D98D',
    color_exponent=0.25,
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
    color_cardColor='#96D98D',
    color_exponent=0.25,
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
    color_cardColor='#96D98D',
    color_exponent=0.25,
    intervalFactor=2,
  );

local taskscalerTasksSaturation =
  basic.timeseries(
    'Taskscaler tasks saturation',
    legendFormat='{{shard}}',
    format='percentunit',
    query=|||
      sum by(shard) (
          fleeting_taskscaler_tasks{environment=~"$environment", stage=~"$stage", instance=~"${runner_manager:pipe}"}
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
    fill=1,
    stack=true,
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
    fill=1,
    stack=true,
    query=|||
      sum by(shard, state) (
          fleeting_taskscaler_tasks{environment=~"$environment", stage=~"$stage", instance=~"${runner_manager:pipe}"}
      )
    |||,
  );

{
  provisionerMaxInstances: provisionerMaxInstances,
  provisionerInstancesSaturation: provisionerInstancesSaturation,
  provisionerInstancesStates: provisionerInstancesStates,
  provisionerMissedUpdates: provisionerMissedUpdates,
  provisionerInstanceOperationsRate: provisionerInstanceOperationsRate,
  provisionerCreationTiming: provisionerCreationTiming,
  provisionerIsRunningTiming: provisionerIsRunningTiming,
  provisionerDeletionTiming: provisionerDeletionTiming,
  taskscalerTasksSaturation: taskscalerTasksSaturation,
  taskscalerOperationsRate: taskscalerOperationsRate,
  taskscalerTasks: taskscalerTasks,
}
