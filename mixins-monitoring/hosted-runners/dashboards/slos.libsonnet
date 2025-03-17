local sloPanels = import './panels/slos.libsonnet';
local templates = import 'grafana/templates.libsonnet';
local grafana = import 'grafonnet/grafana.libsonnet';
local basic = import 'runbooks/libsonnet/grafana/basic.libsonnet';

local row = grafana.row;

{
  _runnerManagerTemplate:: $._config.templates.runnerManager,

  grafanaDashboards+:: {
    'hosted-runners-slos.json':
      local dashboard = basic.dashboard(
        title='Hosted Runners SLOs',
        description='Hosted Runners SLOs over the past month',
        tags=['hosted-runners', 'slas', 'service-levels'],
        editable=false,
        includeStandardEnvironmentAnnotations=false,
        includeEnvironmentTemplate=false,
        defaultDatasource=$._config.prometheusDatasource,
        time_from='now-1M/M',
        time_to='now-1d',
      );

      local panels = sloPanels.new({
        type: 'hosted-runners',
      });

      dashboard
      .addPanel(
        row.new(title='Hosted runners ci_runner_jobs availability'),
        gridPos={ h: 1, w: 24, x: 0, y: 0 }
      )
      .addPanel(
        panels.overallAvailability,
        gridPos={ h: 8, w: 4, x: 0, y: 1 }
      )
      .addPanel(
        panels.budgetSpent,
        gridPos={ h: 8, w: 5, x: 4, y: 1 }
      )
      .addPanel(
        panels.rollingAvailability,
        gridPos={ h: 8, w: 12, x: 9, y: 1 }
      )
      // Add a new row for job queuing SLO
      .addPanel(
        row.new(title='Hosted runners job queuing SLO'),
        gridPos={ h: 1, w: 24, x: 0, y: 9 }
      )
      .addPanel(
        panels.jobQueuingSLO,
        gridPos={ h: 8, w: 4, x: 0, y: 10 }
      )
      .addPanel(
        panels.queuingViolationsCount,
        gridPos={ h: 8, w: 5, x: 4, y: 10 }
      )
      .addPanel(
        panels.jobQueuingSLOOverTime,
        gridPos={ h: 8, w: 12, x: 9, y: 10 }
      ),
  },
}
