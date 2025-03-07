local grafana = import 'grafonnet/grafana.libsonnet';
local basic = import 'runbooks/libsonnet/grafana/basic.libsonnet';
local layout = import 'runbooks/libsonnet/grafana/layout.libsonnet';

local mappings = import '../lib/mappings.libsonnet';
local runnerPanels = import './panels/runner.libsonnet';

local row = grafana.row;

{
  _runnerManagerTemplate:: $._config.templates.runnerManager,

  grafanaDashboards+:: {
    'hosted-runners.json':
      basic.dashboard(
        title='%s Overview' % $._config.dashboardName,
        tags=$._config.dashboardTags,
        editable=true,
        includeStandardEnvironmentAnnotations=false,
        includeEnvironmentTemplate=false,
        defaultDatasource=$._config.prometheusDatasource
      )
      .addTemplate($._runnerManagerTemplate)
      .addPanels(
        runnerPanels.headlineMetricsRow(
          serviceType='hosted-runners',
          metricsCatalogServiceInfo=$._config.gitlabMetricsConfig.monitoredServices[0],
          selectorHash={},
          showSaturationCell=true
        )
      )
      .addPanels(layout.grid([
        runnerPanels.versionsTable($._config.runnerJobSelector),
        runnerPanels.uptimeTable($._config.runnerJobSelector),
        runnerPanels.notes(
          content=|||
            This is global overview of all hosted runners.

            For more information check the hosted runner dashboard in the runner project.
          |||
        ),
      ], cols=3, rowHeight=6, startRow=0))
      .addPanel(
        row.new(title='Runner Manager Overview'),
        gridPos={ x: 0, y: 1000, w: 24, h: 1 }
      )
      .addPanels(layout.grid([
        runnerPanels.statusPanel(
          title='Runner Manager Status',
          legendFormat='Runner Manager Status',
          query=|||
            sum (
              vector(0) and on() (
                (sum(gitlab_component_shard_ops:rate_5m{component="api_requests", %(runnerNameSelector)s}) by (shard) > 0)
              )
              or vector(1)
            )
          ||| % $._config,
          valueMapping=mappings.onlineStatusMappings
        ),
        runnerPanels.statPanel(
          panelTitle='Total Job Executed',
          query=|||
            gitlab_runner_jobs_total{%(runnerNameSelector)s}
          ||| % $._config,
          color='green'
        ),
        runnerPanels.statPanel(
          panelTitle='Total Failed Jobs',
          query=|||
            sum by(shard) (
              gitlab_runner_failed_jobs_total{%(runnerNameSelector)s}
            )
          ||| % $._config,
          color='red'
        ),
        runnerPanels.statPanel(
          panelTitle='Jobs Running',
          query=|||
            sum by(shard) (
              gitlab_runner_jobs{%(runnerNameSelector)s}
            )
          ||| % $._config
        ),
        runnerPanels.statusPanel(
          title='Job Concurrency Status',
          legendFormat='Job Concurrency Status',
          query=|||
            clamp_min(floor(
              (
                gitlab_component_saturation:ratio{type="hosted-runners", %(runnerNameSelector)s}
              )
            ), 0)
          ||| % $._config,
          valueMapping=mappings.concurrentMappings
        ),
        runnerPanels.statPanel(
          panelTitle='Concurrent Job Limit',
          query=|||
            gitlab_runner_concurrent{%(runnerNameSelector)s}
          ||| % $._config,
          color='yellow'
        ),
      ], cols=6, rowHeight=5, startRow=1001))
      .addPanels(layout.grid([
        runnerPanels.runnerCaughtErrors($._config.runnerNameSelector),
        runnerPanels.jobsCaughtErrors($._config.runnerNameSelector),
        runnerPanels.hostedRunnerSaturation($._config.runnerNameSelector),
      ], cols=3, rowHeight=10, startRow=1002))
      .addPanels(layout.grid([
        runnerPanels.totalApiRequests($._config.runnerNameSelector),
        runnerPanels.runningJobPhase($._config.runnerNameSelector),
        runnerPanels.notes(
          content=|||
            The Grafana Hosted Runner Manager Dashboard for dedicated environments provides a real-time view of GitLab runners' performance.

            It tracks key metrics like job execution times, runner utilization, system health, and alerts for issues such as downtime
            or job failures. This dashboard helps optimize runner performance and resource management in dedicated setups, ensuring efficient CI/CD workflows.
          |||
        ),
      ], cols=3, rowHeight=10, startRow=1003))
      .addPanel(
        row.new(title='Pending Jobs'),
        gridPos={ x: 0, y: 2000, w: 24, h: 100 }
      )
      .addPanels(layout.grid([
        runnerPanels.pendingJobQueueDuration($._config.runnerNameSelector),
        runnerPanels.ciPendingBuilds(),
        runnerPanels.jobQueuingExceeded($._config.runnerNameSelector),
      ], cols=3, rowHeight=10, startRow=2001))
      .addPanels(layout.grid([
        runnerPanels.jobsQueuingFailureRate($._config.runnerNameSelector),
        runnerPanels.averageDurationOfQueuing($._config.runnerNameSelector),
        runnerPanels.differentQueuingPhase(),
      ], cols=3, rowHeight=10, startRow=2002))
      .addPanel(
        row.new(title='Hosted Runner Minutes'),
        gridPos={ x: 0, y: 3000, w: 24, h: 1 }
      )
      .addPanels(layout.grid([
        runnerPanels.finishedJobMinutesIncrease($._config.runnerNameSelector),
        runnerPanels.finishedJobDurationsHistogram($._config.runnerNameSelector),
      ], cols=2, rowHeight=10, startRow=3001))
      .addPanel(
        row.new(title='Hosted Runner Fleeting'),
        gridPos={ x: 0, y: 4000, w: 24, h: 1 }
      ).addPanels(layout.grid([
        runnerPanels.fleetingInstancesSaturation($._config.runnerNameSelector),
        runnerPanels.taskScalerSaturation($._config.runnerNameSelector),
        runnerPanels.taskScalerMaxPerInstance($._config.runnerNameSelector),
      ], cols=3, rowHeight=10, startRow=4001))
      .addPanels(layout.grid([
        runnerPanels.fleetingInstanceCreationTiming($._config.runnerNameSelector),
        runnerPanels.fleetingInstanceRunningTiming($._config.runnerNameSelector),
        runnerPanels.provisionerDeletionTiming($._config.runnerNameSelector),
        runnerPanels.provisionerInstanceLifeDuration($._config.runnerNameSelector),
      ], cols=4, rowHeight=10, startRow=4002))
      .addPanel(
        row.new(title='Polling'),
        gridPos={ x: 0, y: 5000, w: 24, h: 1 }
      ).addPanels(layout.grid([
        runnerPanels.pollingRPS(),
        runnerPanels.pollingError(),
        runnerPanels.notes(
          content=|||
            This SLI monitors job polling operations from runners (not only hosted runners), via Workhorse's /api/v4/jobs/request route.

            5xx responses are considered to be errors, and could indicate postgres timeouts (after 15s) on the main query used in assigning jobs to runners.
          |||
        ),
      ], cols=3, rowHeight=10, startRow=5001)),
  },
}
