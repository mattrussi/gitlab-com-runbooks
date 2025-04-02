local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local keyMetrics = import 'gitlab-dashboards/key_metrics.libsonnet';
local basic = import 'grafana/basic.libsonnet';
local aggregationSets = (import 'gitlab-metrics-config.libsonnet').aggregationSets;
local panel = import 'grafana/time-series/panel.libsonnet';
local target = import 'grafana/time-series/target.libsonnet';

local heatmapPanel = grafana.heatmapPanel;
local text = grafana.text;


local headlineMetricsRow(
  serviceType,
  rowTitle='Hosted Runner(s) Overview',
  metricsCatalogServiceInfo,
  selectorHash,
  showSaturationCell,
      ) =
  local hasApdex = metricsCatalogServiceInfo.hasApdex();
  local hasErrorRate = metricsCatalogServiceInfo.hasErrorRate();
  local hasRequestRate = metricsCatalogServiceInfo.hasRequestRate();
  local selectorHashWithExtras = selectorHash { type: serviceType };

  keyMetrics.headlineMetricsRow(
    serviceType=serviceType,
    startRow=0,
    rowTitle=rowTitle,
    selectorHash=selectorHashWithExtras,
    stableIdPrefix='',
    showApdex=hasApdex,
    legendFormatPrefix='{{component}} - {{shard}}',
    showErrorRatio=hasErrorRate,
    showOpsRate=hasRequestRate,
    showSaturationCell=showSaturationCell,
    compact=false,
    rowHeight=10,
    aggregationSet=aggregationSets.shardComponentSLIs
  );

local notes(title='Notes', content) = text.new(
  title=title,
  mode='markdown',
  content=content
);

local heatmap(
  title,
  query,
  interval='$__rate_interval',
  intervalFactor=3,
  color_mode='opacity',  // alowed are: opacity, spectrum
  color_cardColor='#FA6400',  // used when color_mode='opacity' is set
  color_colorScheme='Oranges',  // used when color_mode='spectrum' is set
  color_exponent=0.5,
  legend_show=false,
  description='',
      ) =
  heatmapPanel.new(
    title=title,
    description=description,
    datasource='$PROMETHEUS_DS',
    legend_show=legend_show,
    yAxis_format='s',
    dataFormat='tsbuckets',
    yAxis_decimals=2,
    color_mode=color_mode,
    color_cardColor=color_cardColor,
    color_colorScheme=color_colorScheme,
    color_exponent=color_exponent,
    cards_cardPadding=1,
    cards_cardRound=2,
    tooltipDecimals=3,
    tooltip_showHistogram=true,
  )
  .addTarget(
    target.prometheus(
      query,
      format='time_series',
      legendFormat='{{le}}',
      interval=interval,
      intervalFactor=intervalFactor,
    ) + {
      dsType: 'influxdb',
      format: 'heatmap',
      orderByTime: 'ASC',
      groupBy: [
        {
          params: ['$__rate_interval'],
          type: 'time',
        },
        {
          params: ['null'],
          type: 'fill',
        },
      ],
      select: [
        [
          {
            params: ['value'],
            type: 'field',
          },
          {
            params: [],
            type: 'mean',
          },
        ],
      ],
    }
  );

local table(title, query, sortBy=[], transform_organize={}, transform_groupBy={}) = (
  basic.table(
    title=title,
    query=query,
    styles=null
  ) {
    options+: {
      sortBy: sortBy,
    },
    transformations: [
      {
        id: 'organize',
        options: transform_organize,
      },
      {
        id: 'groupBy',
        options: {
          fields: transform_groupBy,
        },
      },
    ],
  }
);

local versionsTable(selector) = table(
  title='GitLab Runner(s) Versions',
  query=|||
    gitlab_runner_version_info{%(selector)s}
  ||| % { selector: selector },
  sortBy=[{
    desc: true,
    displayName: 'version',
  }],
  transform_organize={
    excludeByName: {
      Time: true,
      Value: true,
      __name__: true,
      branch: true,
      built_at: true,
      env: true,
      environment: true,
      fqdn: true,
      job: true,
      monitor: true,
      name: true,
      provider: true,
      region: true,
      shard: true,
      stage: true,
      tier: true,
      type: true,
    },
    indexByName: {
      instance: 0,
      runner_id: 1,
      shard: 2,
      version: 3,
      instance_type: 4,
      os: 5,
      architecture: 6,
      go_version: 7,
      revision: 8,
    },
    renameByName: {
      architecture: 'arch',
      go_version: '',
      revision: '',
    },
  },
  transform_groupBy={
    instance: {
      aggregations: ['last'],
      operation: 'aggregate',
    },
  }
) + {
  fieldConfig+: {
    overrides+: [
      {
        matcher: { id: 'byName', options: 'instance' },
        properties: [{ id: 'custom.width', value: 200 }],
      },
      {
        matcher: { id: 'byName', options: 'version' },
        properties: [{ id: 'custom.width', value: 120 }],
      },
      {
        matcher: { id: 'byName', options: 'revision' },
        properties: [{ id: 'custom.width', value: 120 }, { id: 'filterable', value: false }],
      },
      {
        matcher: { id: 'byName', options: 'os' },
        properties: [{ id: 'custom.width', value: 80 }, { id: 'filterable', value: false }],
      },
      {
        matcher: { id: 'byName', options: 'arch' },
        properties: [{ id: 'custom.width', value: 80 }, { id: 'filterable', value: false }],
      },
      {
        matcher: { id: 'byName', options: 'go_version' },
        properties: [{ id: 'custom.width', value: 90 }, { id: 'filterable', value: false }],
      },
      {
        matcher: { id: 'byName', options: 'shard' },
        properties: [{ id: 'custom.width', value: 120 }],
      },
      {
        matcher: { id: 'byName', options: 'runner_id' },
        properties: [{ id: 'custom.width', value: 90 }],
      },
      {
        matcher: { id: 'byName', options: 'instance_type' },
        properties: [{ id: 'custom.width', value: 120 }],
      },
    ],
  },
};

local uptimeTable(selector) = table(
  'GitLab Runner(s) Uptime',
  query=|||
    time() - process_start_time_seconds{%(selector)s}
  ||| % { selector: selector },
  sortBy=[{
    asc: true,
    displayName: 'Uptime (last)',
  }],
  transform_organize={
    excludeByName: {
      Time: true,
      env: true,
      environment: true,
      fqdn: true,
      job: true,
      monitor: true,
      provider: true,
      region: true,
      shard: true,
      stage: true,
      tier: true,
      type: true,
    },
    indexByName: {
      instance: 0,
      Value: 1,
    },
    renameByName: {
      Value: 'Uptime',
    },
  },
  transform_groupBy={
    instance: {
      aggregations: [],
      operation: 'groupby',
    },
    Uptime: {
      aggregations: ['last'],
      operation: 'aggregate',
    },
  }
) + {
  fieldConfig+: {
    defaults+: {
      unit: 's',
    },
    overrides+: [
      {
        matcher: { id: 'byName', options: 'instance' },
        properties: [{ id: 'custom.width', value: null }],
      },
      {
        matcher: { id: 'byName', options: 'Uptime (last)' },
        properties: [{ id: 'custom.width', value: 120 }],
      },
    ],
  },
};

local statPanel(
  panelTitle,
  description='',
  query,
  color='blue'
      ) =
  basic.statPanel(
    title=null,
    panelTitle=panelTitle,
    description=description,
    query=query,
    legendFormat='{{shard}}',
    unit='short',
    decimals=0,
    colorMode='value',
    instant=true,
    interval='1d',
    intervalFactor=1,
    reducerFunction='last',
    justifyMode='center',
    color=color,
  );

local hostedRunnerSaturation(selector) =
  panel.timeSeries(
    title='Runner saturation of concurrent',
    legendFormat='{{ shard }} jobs running',
    linewidth=2,
    format='percentunit',
    yAxisLabel='Saturation %',
    min=0,
    query=|||
      gitlab_component_saturation:ratio{type="hosted-runners", %(selector)s}
    ||| % { selector: selector }
  ).addTarget(
    target.prometheus(
      expr='0.85',
      legendFormat='Soft SLO',
    )
  ).addTarget(
    target.prometheus(
      expr='0.95',
      legendFormat='Hard SLO',
    )
  ).addSeriesOverride({
    alias: '/.*SLO$/',
    color: '#F2495C',
    stack: false,
    dashes: true,
    linewidth: 4,
    dashLength: 4,
    spaceLength: 4,
  });

local totalApiRequests(selector) =
  panel.timeSeries(
    title='Total number of api requests',
    query=|||
      sum by(status, shard, endpoint) (
        increase(
          gitlab_runner_api_request_statuses_total{%(selector)s} [$__rate_interval]
        )
      )
    ||| % { selector: selector },
    legendFormat='{{shard}} : api {{endpoint}} : status {{status}}',
    yAxisLabel='Api requests',
    drawStyle=''
  );

local runningJobPhase(selector) =
  panel.timeSeries(
    title='Running jobs phase',
    yAxisLabel='Running jobs',
    query=|||
      sum by (executor_stage, stage, shard) (
        gitlab_runner_jobs{state="running", %(selector)s}
      )
    ||| % { selector: selector },
    legendFormat='{{shard}} : {{executor_stage}} : {{stage}}',
    drawStyle='bars',
  );

local runnerCaughtErrors(selector) =
  panel.timeSeries(
    title='Runner Manager Caught Errors',
    yAxisLabel='Erros',
    query=|||
      sum (
        rate(
          gitlab_runner_errors_total{%(selector)s} [$__rate_interval]
        )
      ) by (level, shard)
    ||| % { selector: selector },
    legendFormat='{{shard}}: {{level}}',
    drawStyle='bars',
  );

local jobsCaughtErrors(selector) =
  panel.timeSeries(
    title='Failed Job errors',
    yAxisLabel='Erros',
    query=|||
      sum by (shard, failure_reason) (
        rate(gitlab_runner_failed_jobs_total{%(selector)s}[$__rate_interval])
      )
    ||| % { selector: selector },
    legendFormat='{{shard}}: {{failure_reason}}',
    drawStyle='bars',
  );

local statusPanel(title='Status', legendFormat='', query, valueMapping) =
  basic.statPanel(
    title=title,
    panelTitle='',
    color='',
    query=query,
    allValues=false,
    reducerFunction='lastNotNull',
    graphMode='none',
    colorMode='background',
    justifyMode='auto',
    thresholdsMode='absolute',
    unit='none',
    orientation='vertical',
    mappings=valueMapping,
    legendFormat=legendFormat,
  );


local pendingJobQueueDuration(selector) =
  heatmap(
    'Pending job queue duration histogram',
    |||
      sum by (le) (
        increase(
          gitlab_runner_job_queue_duration_seconds_bucket{%(selector)s}[$__rate_interval])
      )
    ||| % { selector: selector },
    color_mode='spectrum',
    color_colorScheme='Oranges',
    legend_show=true,
    intervalFactor=1,
  );

local ciPendingBuilds() =
  panel.timeSeries(
    title='Pending Builds',
    query=|||
      sum by (instance) (increase(
        ci_pending_builds{shared_runners="no"} [$__rate_interval]
      ))
    |||,
    legendFormat='pending builds',
    yAxisLabel='Pending Builds',
    drawStyle='bars',
  );

local jobQueuingExceeded(selector) =
  panel.timeSeries(
    title='Acceptable job queuing duration exceeded',
    query=|||
      sum by (shard) (
        increase(
          gitlab_runner_acceptable_job_queuing_duration_exceeded_total{%(selector)s}[$__rate_interval]
        )
      )
    ||| % { selector: selector },
    legendFormat='{{shard}}',
  );

local jobsQueuingFailureRate(selector) =
  panel.timeSeries(
    title='Jobs Queuing Failure Rate',
    legendFormat='{{shard}}',
    format='percent',
    linewidth=2,
    min=0,
    query=|||
      sum by (shard) (
        rate(
          gitlab_runner_acceptable_job_queuing_duration_exceeded_total{%(selector)s}[$__rate_interval]
        )
      )
      /
      sum by (shard) (
        rate(
          gitlab_runner_jobs_total{%(selector)s}[$__rate_interval]
        )
      )
    ||| % { selector: selector }
  );

local averageDurationOfQueuing(selector) =
  panel.timeSeries(
    title='Average duration of queuing',
    legendFormat='{{shard}}',
    linewidth=2,
    format='s',
    fill=0,
    min=0,
    query=|||
      sum by (shard) (
        rate(gitlab_runner_job_queue_duration_seconds_sum{%(selector)s}[5m])
      )
      /
      sum by (shard) (
        gitlab_component_shard_ops:rate_5m{component="pending_builds", %(selector)s}
      )
    ||| % { selector: selector }
  ).addTarget(
    target.prometheus(
      expr='300',
      legendFormat='Hard SLO',
    )
  ).addSeriesOverride({
    alias: '/.*SLO$/',
    color: '#F2495C',
    dashes: true,
    legend: true,
    lines: true,
    linewidth: 2,
    dashLength: 4,
    spaceLength: 4,
  });

local differentQueuingPhase() =
  panel.timeSeries(
    title='Rate of builds queue operations',
    legendFormat='queuing operation {{ operation }}',
    linewidth=2,
    yAxisLabel='Rate per second',
    query=|||
      sum(
        rate(
          gitlab_ci_queue_operations_total{}[$__interval]
        )
      ) by (operation)
    |||
  );


local finishedJobMinutesIncrease(selector) =
  panel.timeSeries(
    title='Finished Job Minutes Increase',
    legendFormat='{{shard}}',
    linewidth=2,
    min=0,
    format='s',
    query=|||
      sum by(shard) (
        increase(gitlab_runner_job_duration_seconds_sum{%(selector)s}[$__rate_interval])
      )/60
    ||| % { selector: selector },
    drawStyle='bars',
  ).addTarget(
    target.prometheus(
      expr=|||
        avg (
          increase(gitlab_runner_job_duration_seconds_sum{%(selector)s}[$__rate_interval])
        )/60
      ||| % { selector: selector },
      legendFormat='Avg',
    )
  ).addSeriesOverride({
    alias: '/.*Avg$/',
    color: '#ff0000',
    linewidth: 4,
  });

local finishedJobDurationsHistogram(selector) =
  heatmap(
    'Finished Job Durations Histogram',
    |||
      sum by (le) (
        rate(gitlab_runner_job_duration_seconds_bucket{%(selector)s}[$__rate_interval])
      )
    ||| % { selector: selector },
    color_mode='spectrum',
    color_colorScheme='Blues',
    legend_show=true,
    intervalFactor=1,
  );

local fleetingInstancesSaturation(selector) =
  panel.timeSeries(
    title='Fleeting instances saturation',
    query=|||
      sum by(job) (
        fleeting_provisioner_instances{state=~"running|deleting", %(selector)s}
      )
      /
      sum by(job) (
        fleeting_provisioner_max_instances{%(selector)s}
      )
    ||| % { selector: selector },
    legendFormat='{{job}}',
    format='percentunit'
  );

local taskScalerSaturation(selector) =
  panel.timeSeries(
    title='Taskscaler tasks saturation',
    query=|||
      sum by(job) (
        fleeting_taskscaler_tasks{%(selector)s, state!~"idle|reserved"}
      )
      /
      sum by(job) (
        fleeting_provisioner_max_instances{%(selector)s}
        *
        fleeting_taskscaler_max_tasks_per_instance{%(selector)s}
      )
    ||| % { selector: selector },
    legendFormat='{{job}}',
    format='percentunit'
  );

local taskScalerMaxPerInstance(selector) =
  panel.timeSeries(
    title='Taskscaler max use count per instance',
    query=|||
      sum by(job) (
        fleeting_taskscaler_max_use_count_per_instance{%(selector)s}
      )
    ||| % { selector: selector },
    legendFormat='{{job}}',
  );

local fleetingInstanceCreationTiming(selector) =
  heatmap(
    'Fleeting instance creation timing',
    |||
      sum by (le) (
        rate(
          fleeting_provisioner_instance_creation_time_seconds_bucket{%(selector)s}[$__rate_interval]
        )
      )
    ||| % { selector: selector },
    color_mode='spectrum',
    color_colorScheme='Greens',
    legend_show=true,
    intervalFactor=2,
  );

local fleetingInstanceRunningTiming(selector) =
  heatmap(
    'Fleeting instance is_running timing',
    |||
      sum by (le) (
        rate(
          fleeting_provisioner_instance_is_running_time_seconds_bucket{%(selector)s}[$__rate_interval]
        )
      )
    ||| % { selector: selector },
    color_mode='spectrum',
    color_colorScheme='Blues',
    legend_show=true,
    intervalFactor=2,
  );

local provisionerDeletionTiming(selector) =
  heatmap(
    'Fleeting instance deletion timing',
    |||
      sum by (le) (
        rate(
          fleeting_provisioner_instance_deletion_time_seconds_bucket{%(selector)s}[$__rate_interval]
        )
      )
    ||| % { selector: selector },
    color_mode='spectrum',
    color_colorScheme='Reds',
    legend_show=true,
    intervalFactor=2,
  );

local provisionerInstanceLifeDuration(selector) =
  heatmap(
    'Fleeting instance life duration',
    |||
      sum by (le) (
        rate(
          fleeting_provisioner_instance_life_duration_seconds_bucket{%(selector)s}[$__rate_interval]
        )
      )
    ||| % { selector: selector },
    color_mode='spectrum',
    color_colorScheme='Purples',
    legend_show=true,
    intervalFactor=2,
  );

local pollingRPS() =
  panel.timeSeries(
    title='Polling RPS - Overall',
    legendFormat='overall',
    linewidth=2,
    yAxisLabel='Requests per second',
    query=|||
      sum by () (
        gitlab_component_shard_ops:rate_5m{component="polling", type="hosted-runners"}
      )
    |||
  );

local pollingError() =
  panel.timeSeries(
    title='Polling Error - Overall',
    legendFormat='overall',
    linewidth=2,
    yAxisLabel='Errors',
    query=|||
      sum by () (
        gitlab_component_shard_errors:rate_5m{component="polling", type="hosted-runners"}
      )
    |||
  );

{
  headlineMetricsRow:: headlineMetricsRow,
  notes:: notes,
  heatmap:: heatmap,
  versionsTable:: versionsTable,
  uptimeTable:: uptimeTable,
  statPanel:: statPanel,
  hostedRunnerSaturation:: hostedRunnerSaturation,
  totalApiRequests:: totalApiRequests,
  runningJobPhase:: runningJobPhase,
  runnerCaughtErrors:: runnerCaughtErrors,
  jobsCaughtErrors:: jobsCaughtErrors,
  pendingJobQueueDuration:: pendingJobQueueDuration,
  ciPendingBuilds:: ciPendingBuilds,
  jobQueuingExceeded:: jobQueuingExceeded,
  jobsQueuingFailureRate:: jobsQueuingFailureRate,
  averageDurationOfQueuing:: averageDurationOfQueuing,
  differentQueuingPhase:: differentQueuingPhase,
  finishedJobMinutesIncrease:: finishedJobMinutesIncrease,
  finishedJobDurationsHistogram:: finishedJobDurationsHistogram,
  fleetingInstancesSaturation:: fleetingInstancesSaturation,
  taskScalerSaturation:: taskScalerSaturation,
  taskScalerMaxPerInstance:: taskScalerMaxPerInstance,
  fleetingInstanceCreationTiming:: fleetingInstanceCreationTiming,
  fleetingInstanceRunningTiming:: fleetingInstanceRunningTiming,
  provisionerDeletionTiming:: provisionerDeletionTiming,
  provisionerInstanceLifeDuration:: provisionerInstanceLifeDuration,
  statusPanel:: statusPanel,
  pollingRPS:: pollingRPS,
  pollingError:: pollingError,
}
