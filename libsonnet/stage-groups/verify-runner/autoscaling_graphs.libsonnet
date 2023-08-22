local panels = import './panels.libsonnet';
local basic = import 'grafana/basic.libsonnet';
local promQuery = import 'grafana/prom_query.libsonnet';
local seriesOverrides = import 'grafana/series_overrides.libsonnet';

local runnersManagerMatching = import './runner_managers_matching.libsonnet';

local vmStates(partition=runnersManagerMatching.defaultPartition) =
  basic.timeseries(
    'Autoscaled VMs states',
    legendFormat='{{shard}}: {{state}}',
    format='short',
    query=runnersManagerMatching.formatQuery(|||
      sum by(shard, state) (
        gitlab_runner_autoscaling_machine_states{environment=~"$environment", stage=~"$stage", executor="docker+machine", %(runnerManagersMatcher)s}
      )
    |||, partition),
  );

local vmOperationsRate(partition=runnersManagerMatching.defaultPartition) =
  basic.timeseries(
    'Autoscaled VM operations rate',
    legendFormat='{{shard}}: {{action}}',
    format='ops',
    fill=1,
    stack=true,
    query=runnersManagerMatching.formatQuery(|||
      sum by (shard, action) (
        increase(gitlab_runner_autoscaling_actions_total{environment=~"$environment", stage=~"$stage", executor="docker+machine", %(runnerManagersMatcher)s}[$__rate_interval])
      )
    |||, partition),
  );

local vmCreationTiming(partition=runnersManagerMatching.defaultPartition) =
  panels.heatmap(
    'Autoscaled VMs creation timing',
    runnersManagerMatching.formatQuery(|||
      sum by (le) (
        increase(gitlab_runner_autoscaling_machine_creation_duration_seconds_bucket{environment=~"$environment", stage=~"$stage", executor="docker+machine",%(runnerManagersMatcher)s}[$__rate_interval])
      )
    |||, partition),
    color_mode='spectrum',
    color_colorScheme='Greens',
    legend_show=true,
    intervalFactor=2,
  );

local gcpRegionQuotas =
  basic.timeseries(
    'GCP region quotas',
    legendFormat='{{project}}: {{region}}: {{quota}}',
    format='percentunit',
    query=|||
      sum by(project, region, quota) (
        (
          gcp_exporter_region_quota_usage{environment=~"$environment", stage=~"$stage", instance=~"$gcp_exporter",project=~"${gcp_project:pipe}",region=~"${gcp_region:pipe}"}
          /
          gcp_exporter_region_quota_limit{environment=~"$environment", stage=~"$stage", instance=~"$gcp_exporter",project=~"${gcp_project:pipe}",region=~"${gcp_region:pipe}"}
        ) > 0
      )
    |||,
  ).addTarget(
    promQuery.target(
      expr='0.85',
      legendFormat='Soft SLO',
    )
  ).addTarget(
    promQuery.target(
      expr='0.9',
      legendFormat='Hard SLO',
    )
  ).addSeriesOverride(
    seriesOverrides.hardSlo
  ).addSeriesOverride(
    seriesOverrides.softSlo
  );

local gcpInstances =
  basic.timeseries(
    'GCP instances',
    legendFormat='{{runner_group}} - {{zone}} - {{machine_type_short}}',
    format='short',
    fill=1,
    stack=true,
    query=|||
      sum by (zone, machine_type_short, runner_group) (
        label_replace(
          label_replace(
            gcp_exporter_instances_count{environment=~"$environment", stage=~"$stage", instance=~"$gcp_exporter",project="${gcp_project:pipe}",zone=~"(${gcp_region:pipe}).*"},
            "machine_type_short",
            "$1",
            "machine_type",
            ".*/([^/]+)$"
          ),
          "runner_group",
          "$2",
          "tags",
          "(.*,)?(srm|prm|gsrm)(,.*)?"
        )
      )
    |||,
  );

{
  vmStates:: vmStates,
  vmOperationsRate:: vmOperationsRate,
  vmCreationTiming:: vmCreationTiming,
  gcpRegionQuotas:: gcpRegionQuotas,
  gcpInstances:: gcpInstances,
}
