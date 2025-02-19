local mappings = import '../lib/mappings.libsonnet';
local panels = import '../lib/panels.libsonnet';
local grafana = import 'grafonnet/grafana.libsonnet';
local basic = import 'runbooks/libsonnet/grafana/basic.libsonnet';
local layout = import 'runbooks/libsonnet/grafana/layout.libsonnet';

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
        panels.headlineMetricsRow(
          serviceType='hosted-runners',
          metricsCatalogServiceInfo=$._config.gitlabMetricsConfig.monitoredServices[0],
          selectorHash={},
          showSaturationCell=true
        )
      )
      .addPanels(layout.grid([
        panels.versionsTable($._config.runnerJobSelector),
        panels.uptimeTable($._config.runnerJobSelector),
        panels.notes(
          content=|||
            This is global overview of all hosted runner.

            For more information check the hosted runner dashboard in the ruuner project.
          |||
        ),
      ], cols=3, rowHeight=6, startRow=0))
      .addPanel(
        row.new(title='Runner Manager Overview'),
        gridPos={ x: 0, y: 1000, w: 24, h: 1 }
      )
      .addPanels(layout.grid([
        panels.statusPanel(
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
        panels.statPanel(
          panelTitle='Total Job Executed',
          query=|||
            gitlab_runner_jobs_total{%(runnerNameSelector)s}
          ||| % $._config,
          color='green'
        ),
        panels.statPanel(
          panelTitle='Total Failed Jobs',
          query=|||
            sum by(shard) (
              gitlab_runner_failed_jobs_total{%(runnerNameSelector)s}
            )
          ||| % $._config,
          color='red'
        ),
        panels.statPanel(
          panelTitle='Jobs Running',
          query=|||
            sum by(shard) (
              gitlab_runner_jobs{%(runnerNameSelector)s}
            )
          ||| % $._config
        ),
        panels.statusPanel(
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
        panels.statPanel(
          panelTitle='Concurrent Job Limit',
          query=|||
            gitlab_runner_concurrent{%(runnerNameSelector)s}
          ||| % $._config,
          color='yellow'
        ),
      ], cols=6, rowHeight=5, startRow=1001))
      .addPanels(layout.grid([
        panels.runnerCaughtErrors($._config.runnerNameSelector),
        panels.jobsCaughtErrors($._config.runnerNameSelector),
        panels.hostedRunnerSaturation($._config.runnerNameSelector),
      ], cols=3, rowHeight=10, startRow=1002))
      .addPanels(layout.grid([
        panels.totalApiRequests($._config.runnerNameSelector),
        panels.runningJobPhase($._config.runnerNameSelector),
        panels.notes(
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
        panels.pendingJobQueueDuration($._config.runnerNameSelector),
        panels.ciPendingBuilds(),
        panels.jobQueuingExceeded($._config.runnerNameSelector),
      ], cols=3, rowHeight=10, startRow=2001))
      .addPanels(layout.grid([
        panels.jobsQueuingFailureRate($._config.runnerNameSelector),
        panels.averageDurationOfQueuing($._config.runnerNameSelector),
        panels.differentQueuingPhase(),
      ], cols=3, rowHeight=10, startRow=2002))
      .addPanel(
        row.new(title='Hosted Runner Minutes'),
        gridPos={ x: 0, y: 3000, w: 24, h: 1 }
      )
      .addPanels(layout.grid([
        panels.finishedJobMinutesIncrease($._config.runnerNameSelector),
        panels.finishedJobDurationsHistogram($._config.runnerNameSelector),
      ], cols=2, rowHeight=10, startRow=3001))
      .addPanel(
        row.new(title='Hosted Runner Fleeting'),
        gridPos={ x: 0, y: 4000, w: 24, h: 1 }
      ).addPanels(layout.grid([
        panels.fleetingInstancesSaturation($._config.runnerNameSelector),
        panels.taskScalerSaturation($._config.runnerNameSelector),
        panels.taskScalerMaxPerInstance($._config.runnerNameSelector),
      ], cols=3, rowHeight=10, startRow=4001))
      .addPanels(layout.grid([
        panels.fleetingInstanceCreationTiming($._config.runnerNameSelector),
        panels.fleetingInstanceRunningTiming($._config.runnerNameSelector),
        panels.provisionerDeletionTiming($._config.runnerNameSelector),
        panels.provisionerInstanceLifeDuration($._config.runnerNameSelector),
      ], cols=4, rowHeight=10, startRow=4002))
      .addPanel(
        row.new(title='Polling'),
        gridPos={ x: 0, y: 5000, w: 24, h: 1 }
      ).addPanels(layout.grid([
        panels.pollingRPS(),
        panels.pollingError(),
        panels.notes(
          content=|||
            This SLI monitors job polling operations from runners (not only hosted runners), via Workhorse's /api/v4/jobs/request route.

            5xx responses are considered to be errors, and could indicate postgres timeouts (after 15s) on the main query used in assigning jobs to runners.
          |||
        )
      ], cols=3, rowHeight=10, startRow=5001)),
  },
}
