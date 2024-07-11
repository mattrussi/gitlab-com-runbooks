local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local basic = import 'gitlab.com/gitlab-com/runbooks/libsonnet/grafana/basic.libsonnet';
local layout = import 'gitlab.com/gitlab-com/runbooks/libsonnet/grafana/layout.libsonnet';
local promQuery = import 'gitlab.com/gitlab-com/runbooks/libsonnet/grafana/prom_query.libsonnet';
local c = import '../config.libsonnet';
local panels = import '../lib/panels.libsonnet';
local templates = import '../lib/templates.libsonnet';

local row = grafana.row;


//////////////////////////////
/// Stat Panels - Overview
//////////////////////////////
local versionPanel() =
  basic.statPanel(
    title=null,
    panelTitle='GitLab Runner Version',
    description='Runner version',
    query='gitlab_runner_version_info{job="$runner"}',
    format='table',
    unit='none',
    colorMode='value',
    fields='version',
    color='light-blue'
  );

local concurrentJobsPanel() =
  basic.statPanel(
    title=null,
    panelTitle='Global concurrent jobs',
    description='Runner concurrent',
    query='gitlab_runner_concurrent{job="$runner"}',
    format='table',
    unit='none',
    colorMode='value',
    fields='Value',
    color='light-blue'
  );


local totalJobsPanel() =
  basic.statPanel(
    title=null,
    panelTitle='Total jobs executed',
    description='Total jobs executed',
    query='gitlab_runner_jobs_total{job="$runner"}',
    format='table',
    unit='none',
    colorMode='value',
    fields='Value',
    color='light-blue'
  );

local totalFailedJobsPanel() =
  basic.statPanel(
    title=null,
    panelTitle='Total failed jobs',
    description='Total failed jobs',
    query='sum(gitlab_runner_failed_jobs_total{job="$runner"}) by (runner)',
    format='table',
    unit='none',
    colorMode='value',
    fields='Value',
    color='red'
  );


//////////////////////////////
/// Time Series Panels - Overview
//////////////////////////////
local jobsRunning() =
  basic.timeseries(
    title='Jobs running',
    query=|||
      sum by(job) (
        gitlab_runner_jobs{job="$runner"}
      )
    |||,
    legendFormat='{{job}}',
    interval='30s'
  );

local averageDurationOfJobs() =
  basic.timeseries(
    title='Average duration of jobs',
    query=|||
      sum (
        rate(
          gitlab_runner_job_duration_seconds_sum{job="$runner"} [$__rate_interval]
        ) /
        rate(
          gitlab_runner_job_duration_seconds_count{job="$runner"} [$__rate_interval]
        )
      ) by (runner,job)
    |||,
    legendFormat='{{job}} : {{runner}}',
    format='s',
  ) + {
    lines: false,
    bars: true,
  };

local counterTrackingOfRequestConcurrency() =
  basic.timeseries(
    title='Counter tracking exceeding of request concurrency',
    query=|||
      rate(
        gitlab_runner_request_concurrency_exceeded_total{job="$runner"} [$__rate_interval]
      )
    |||,
    legendFormat='{{job}} : {{runner}}',
  ) + {
    lines: false,
    bars: true,
  };

local caughtErrors() =
  basic.timeseries(
    title='The number of caught errors',
    query=|||
      sum (
        rate(
          gitlab_runner_errors_total{job="$runner"} [$__rate_interval]
        )
      ) by (level,job)
    |||,
    legendFormat='{{job}} : {{level}}',
  ) + {
    lines: false,
    bars: true,
  };

//////////////////////////////
/// Time Series Panels - Overview
//////////////////////////////
local totalApiRequests() =
  basic.timeseries(
    title='Total number of api requests',
    query=|||
      rate(
        gitlab_runner_api_request_statuses_total{job="$runner"} [$__rate_interval]
      )
    |||,
    legendFormat='{{runner}} : api {{endpoint}} : status {{status}}',
  ) + {
    lines: false,
    bars: true,
  };

local runningJobPhase() =
  basic.timeseries(
    title='Running jobs phase',
    query=|||
      sum(
        gitlab_runner_jobs{state="running", job="$runner"}
      ) by (job, executor_stage, stage, runner)
    |||,
    legendFormat='{{job}} : {{runner}} : {{executor_stage}} : {{stage}} '
  ) + {
    lines: false,
    bars: true,
  };

local runnerSaturation() =
  basic.timeseries(
    title='Runner saturation of concurrent',
    legendFormat='{{job}}',
    format='percentunit',
    query=|||
      sum by (job) (
        gitlab_runner_jobs{job="$runner"}
      )
      /
      sum by (job) (
        gitlab_runner_concurrent{job="$runner"}
      )
    |||
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
  );

//////////////////////////////
/// Pending Job panels
//////////////////////////////
local pendingJobQueueDuration() =
  panels.heatmap(
    'Pending job queue duration histogram',
    |||
      sum by (le) (
        increase(gitlab_runner_job_queue_duration_seconds_bucket{job="$runner"}[$__rate_interval])
      )
    |||,
    color_mode='spectrum',
    color_colorScheme='Oranges',
    legend_show=true,
    intervalFactor=1,
  );

local queuingFailureRate() =
  basic.timeseries(
    title='Pending Builds',
    query=|||
      increase(
       ci_pending_builds [$__rate_interval]
      )
    |||,
  ) + {
    lines: false,
    bars: true,
    legend: {
      show: false,
    },
  };

local averageDurationOfQueing() =
  basic.timeseries(
    title='Average duration of queing',
    query=|||
      sum(
        rate(
          gitlab_runner_job_queue_duration_seconds_sum{job="$runner"}[$__rate_interval]
        )
      ) by (job)
      /
      sum(
        rate(
          gitlab_runner_job_queue_duration_seconds_count{job="$runner"} [$__rate_interval]
        )
      ) by (job)
    |||,
    format='s',
    legendFormat='{{job}} : {{runner}}',
  ) + {
    lines: false,
    bars: true,
  };

//////////////////////////////
/// Fleeting instances
//////////////////////////////
local fleetingInstancesSaturation() =
  basic.timeseries(
    title='Fleeting instances saturation',
    query=|||
      sum by(job) (
        fleeting_provisioner_instances{state=~"running|deleting", job="$runner"}
      )
      /
      sum by(job) (
        fleeting_provisioner_max_instances{job="$runner"}
      )
    |||,
    legendFormat='{{job}}',
    format='percentunit'
  );

local taskScalerSaturation() =
  basic.timeseries(
    title='Taskscaler tasks saturation',
    query=|||
      sum by(job) (
        fleeting_taskscaler_tasks{job="$runner", state!~"idle|reserved"}
      )
      /
      sum by(job) (
        fleeting_provisioner_max_instances{job="$runner"}
        *
        fleeting_taskscaler_max_tasks_per_instance{job="$runner"}
      )
    |||,
    legendFormat='{{job}}',
    format='percentunit'
  );

local taskScalerMaxPerInstance() =
  basic.timeseries(
    title='Taskscaler max use count per instance',
    query=|||
      sum by(job) (
        fleeting_taskscaler_max_use_count_per_instance{job=~"$runner"}
      )
    |||,
    legendFormat='{{job}}',
  );

local fleetingInstanceCreationTiming() =
  panels.heatmap(
    'Fleeting instance creation timing',
    |||
      sum by (le) (
        rate(
          fleeting_provisioner_instance_creation_time_seconds_bucket{job="$runner"}[$__rate_interval]
        )
      )
    |||,
    color_mode='spectrum',
    color_colorScheme='Greens',
    legend_show=true,
    intervalFactor=2,
  );

local fleetingInstanceRunningTiming() =
  panels.heatmap(
    'Fleeting instance is_running timing',
    |||
      sum by (le) (
        rate(
          fleeting_provisioner_instance_is_running_time_seconds_bucket{job="$runner"}[$__rate_interval]
        )
      )
    |||,
    color_mode='spectrum',
    color_colorScheme='Blues',
    legend_show=true,
    intervalFactor=2,
  );

local provisionerDeletionTiming() =
  panels.heatmap(
    'Fleeting instance deletion timing',
    |||
      sum by (le) (
        rate(
          fleeting_provisioner_instance_deletion_time_seconds_bucket{job="$runner"}[$__rate_interval]
        )
      )
    |||,
    color_mode='spectrum',
    color_colorScheme='Reds',
    legend_show=true,
    intervalFactor=2,
  );

local provisionerInstanceLifeDuration() =
  panels.heatmap(
    'Fleeting instance life duration',
    |||
      sum by (le) (
        rate(
          fleeting_provisioner_instance_life_duration_seconds_bucket{job="$runner"}[$__rate_interval]
        )
      )
    |||,
    color_mode='spectrum',
    color_colorScheme='Purples',
    legend_show=true,
    intervalFactor=2,
  );

{
  _runnerManagerTemplate:: templates.runnerManager,

  grafanaDashboards+:: {
    'main.json':
      basic.dashboard(
        title='%s Overview' % $._config.dashboardNamePrefix,
        tags=$._config.dashboardTags,
        editable=true,
        includeStandardEnvironmentAnnotations=false,
        includeEnvironmentTemplate=false,
        defaultDatasource=$._config.prometheusDatasource
      )
      .addTemplate($._runnerManagerTemplate)
      .addPanel(
        row.new(title='Overview'),
        gridPos={ x: 0, y: 0, w: 24, h: 1 }
      )
      .addPanels(layout.grid([
        versionPanel(),
        concurrentJobsPanel(),
        totalJobsPanel(),
        totalFailedJobsPanel(),
      ], cols=4, rowHeight=5, startRow=0))
      .addPanels(layout.grid([
        jobsRunning(),
        averageDurationOfJobs(),
        counterTrackingOfRequestConcurrency(),
        caughtErrors(),
      ], cols=4, rowHeight=10, startRow=20))
      .addPanels(layout.grid([
        totalApiRequests(),
        runningJobPhase(),
        runnerSaturation(),
      ], cols=3, rowHeight=10, startRow=30))
      .addPanel(
        row.new(title='Job queue timings'),
        gridPos={ x: 0, y: 40, w: 24, h: 1 }
      )
      .addPanels(layout.grid([
        averageDurationOfQueing(),
        pendingJobQueueDuration(),
        queuingFailureRate(),
      ], cols=3, rowHeight=10, startRow=40))
      .addPanel(
        row.new(title='Fleeting instances'),
        gridPos={ x: 0, y: 80, w: 24, h: 1 }
      )
      .addPanels(layout.grid([
        fleetingInstancesSaturation(),
        taskScalerSaturation(),
        taskScalerMaxPerInstance(),
      ], cols=3, rowHeight=10, startRow=80))
      .addPanels(layout.grid([
        fleetingInstanceCreationTiming(),
        fleetingInstanceRunningTiming(),
        provisionerInstanceLifeDuration(),
        provisionerDeletionTiming(),
      ], cols=4, rowHeight=10, startRow=90)),
  },
}
