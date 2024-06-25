local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local basic = import 'grafana/basic.libsonnet';
local template = grafana.template;
local g = import 'github.com/grafana/grafonnet/gen/grafonnet-latest/main.libsonnet';
local prometheusQuery = g.query.prometheus;
local row = grafana.row;
local mimirHelper = import 'services/lib/mimir-helpers.libsonnet';

local queries = {
  totalBlockersCount:
    prometheusQuery.new(
      '$PROMETHEUS_DS',
      |||
        sum by (root_cause) (
          last_over_time(
            delivery_deployment_blocker_count{
                root_cause=~".+",
                root_cause!="RootCause::FlakyTest"
                }
          [1d])
        )
      |||
    )
    + prometheusQuery.withFormat("time_series"),

  totalGprdHoursBlocked:
    prometheusQuery.new(
      '$PROMETHEUS_DS',
      |||
        sum by (root_cause) (
          last_over_time(
            delivery_deployment_hours_blocked{
              target_env="gprd",
              root_cause=~".+",
              root_cause!="RootCause::FlakyTest"
              }
            [1d])
        )
      |||
    )
    + prometheusQuery.withFormat("time_series"),

  totalGstgHoursBlocked:
    prometheusQuery.new(
      '$PROMETHEUS_DS',
      |||
        sum by (root_cause) (
          last_over_time(
            delivery_deployment_hours_blocked{
              target_env="gstg",
              root_cause=~".+",
              root_cause!="RootCause::FlakyTest"}
            [1d])
        )
      |||
    )
    + prometheusQuery.withFormat("time_series"),

  blockersCount(root_cause):
    prometheusQuery.new(
      '$PROMETHEUS_DS',
      |||
        max by(week) (
          last_over_time(
            delivery_deployment_blocker_count{
              root_cause=root_cause
              }
            [1d])
        )
      |||
    )
    + prometheusQuery.withFormat("table"),

  gprdHoursBlocked(root_cause):
    prometheusQuery.new(
      '$PROMETHEUS_DS',
      |||
        max by(week) (
          last_over_time(
            delivery_deployment_hours_blocked{
              root_cause=root_cause,
              target_env="gprd"
              }
            [1d])
        )
      |||
    )
    + prometheusQuery.withFormat("table"),

  gstgHoursBlocked(root_cause):
    prometheusQuery.new(
      '$PROMETHEUS_DS',
      |||
        max by(week) (
          last_over_time(
            delivery_deployment_hours_blocked{
              root_cause=root_cause,
              target_env="gstg"
              }
            [1d])
        )
      |||
    )
    + prometheusQuery.withFormat("table"),

  tabulatedDeploymentBlockers(root_cause):
    [
      prometheusQuery.new(
        '$PROMETHEUS_DS',
        |||
          max by(week) (
            last_over_time(
              delivery_deployment_blocker_count{
                root_cause=root_cause
                }
              [1d])
          )
        |||
      )
      + prometheusQuery.withFormat("time_series"),
    ] + [
      prometheusQuery.new(
        '$PROMETHEUS_DS',
        |||
          max by(week) (
            last_over_time(
              delivery_deployment_hours_blocked{
                root_cause=root_cause,
                target_env="gprd"}
              [1d])
            )
        |||
      )
      + prometheusQuery.withFormat("time_series"),
    ] + [
      prometheusQuery.new(
        '$PROMETHEUS_DS',
        |||
          max by(week) (
            last_over_time(
              delivery_deployment_hours_blocked{
                root_cause=root_cause,
                target_env="gstg"}
              [1d])
            )
        |||
      )
      + prometheusQuery.withFormat("time_series"),
    ],
};

local panels = {
  text: {
    textPanel(title):
      g.panel.text.new(title)
      + g.panel.text.options.withMode("markdown")
      + g.panel.text.options.withContent(|||
          # Deployment Blockers

          Deployment failures are currently automatically captured under [release/tasks issues](https://gitlab.com/gitlab-org/release/tasks/-/issues).
          Release managers are responsible for labeling these failures with appropriate `RootCause::*` labels. By the start of the following week (Monday), the `deployments:blockers_report` scheduled pipeline in the [release/tools](https://ops.gitlab.net/gitlab-org/release/tools/-/pipeline_schedules) repo reviews the labeled issues and generates a weekly deployment blockers issue, like this [one](https://gitlab.com/gitlab-org/release/tasks/-/issues/11125).

          This dashboard tracks the trend of recurring root causes for deployment blockers. Each root cause is displayed in separate rows with three panels: one for the count of blockers, one for `gprd` hours blocked, and one for `gstg` hours blocked. At the top, there is an overview of the failure types, including the total calculations for the entire specified time window.

          Links:
          - [List of root causes](https://gitlab.com/gitlab-org/release/tasks/-/labels?subscribed=&sort=relevance&search=RootCause)
          - [Deployments metrics review](https://gitlab.com/groups/gitlab-com/gl-infra/-/epics/1192)
        |||)
  },

  barChart: {
    barChartPanel(title, query):
      g.panel.barChart.new(title)
      + g.panel.barChart.queryOptions.withTargets([query])
      + g.panel.barChart.queryOptions.withInterval('2d')
      + g.panel.barChart.options.withOrientation("horizontal")
      + g.panel.barChart.options.legend.withDisplayMode('table')
      + g.panel.barChart.options.legend.withPlacement("bottom")
      + g.panel.barChart.options.legend.withCalcs(['total'])
      + g.panel.barChart.standardOptions.withDisplayName("blockers_count")
      + g.panel.barChart.standardOptions.color.withMode("thresholds")
      + g.panel.barChart.queryOptions.withTransformations([
        g.panel.barChart.queryOptions.transformation.withId("reduce")
        + g.panel.barChart.queryOptions.transformation.withOptions({ reducers: ['sum'] })
      ])
  },

  trend: {
    trendPanel(title, query):
      g.panel.trend.new(title)
      + g.panel.trend.queryOptions.withTargets([query])
      + g.panel.trend.queryOptions.withInterval('2d')
      + g.panel.trend.options.withXField("week_index")
      + g.panel.trend.options.legend.withDisplayMode('list')
      + g.panel.trend.options.legend.withPlacement("bottom")
      + g.panel.trend.fieldConfig.defaults.custom.withDrawStyle("line")
      + g.panel.trend.fieldConfig.defaults.custom.withLineInterpolation("linear")
      + g.panel.trend.fieldConfig.defaults.custom.withLineWidth(1)
      + g.panel.trend.fieldConfig.defaults.custom.withShowPoints("always")
      + g.panel.trend.fieldConfig.defaults.custom.withSpanNulls(true)
      + g.panel.trend.fieldConfig.defaults.custom.withAxisBorderShow(true)
      + g.panel.trend.fieldConfig.defaults.custom.withAxisSoftMin(1)
      + g.panel.trend.standardOptions.withDecimals(0)
      + g.panel.trend.standardOptions.withUnit("short")
      + g.panel.trend.standardOptions.withMin(1)
      + g.panel.trend.standardOptions.color.withMode("palette-classic")
      + g.panel.trend.standardOptions.withOverrides([
        g.panel.trend.standardOptions.override.byName.new('week_index')
        + g.panel.trend.standardOptions.override.byName.withPropertiesFromOptions(
          g.panel.trend.fieldConfig.defaults.custom.withAxisLabel("week_index")
          + g.panel.trend.fieldConfig.defaults.custom.withAxisPlacement("hidden")
        )
      ])
      + g.panel.trend.queryOptions.withTransformations([
        g.panel.trend.queryOptions.transformation.withId("calculateField")
        + g.panel.trend.queryOptions.transformation.withOptions({
          alias: "count",
          binary: {
            left: "week"
          },
          mode: "index",
          reduce: {
            reducer: "sum"
          }
        }),
        g.panel.trend.queryOptions.transformation.withId("calculateField")
        + g.panel.trend.queryOptions.transformation.withOptions({
          alias: "week_index",
          binary: {
            left: "count",
            right: "1"
          },
          mode: "index",
          reduce: {
            reducer: "sum"
          }
        }),
        g.panel.trend.queryOptions.transformation.withId("organize")
        + g.panel.trend.queryOptions.transformation.withOptions({
          excludeByName: {
            Time: false,
            count: true
          },
          includeByName: {},
          indexByName: {},
          renameByName: {
            "Trend #blocker_count": "blocker_count",
            "Value": "blockers_count",
            "week_count": "week_index"
          }
        })
      ])
  },

  table: {
    tablePanel(title, query):
      g.panel.table.new(title)
      + g.panel.table.queryOptions.withTargets(query)
      + g.panel.table.queryOptions.withInterval('2d')
      + g.panel.table.fieldConfig.defaults.custom.withFilterable(true)
      + g.panel.table.options.withShowHeader(true)
      + g.panel.table.standardOptions.color.withMode("thresholds")
      + g.panel.table.queryOptions.withTransformations([
        g.panel.table.queryOptions.transformation.withId("timeSeriesTable")
        + g.panel.table.queryOptions.transformation.withOptions({}),
        g.panel.table.queryOptions.transformation.withId("merge")
        + g.panel.table.queryOptions.transformation.withOptions({}),
        g.panel.table.queryOptions.transformation.withId("calculateField")
        + g.panel.table.queryOptions.transformation.withOptions({
          alias: "count",
          mode: "index",
          reduce: {
            reducer: "sum"
          }
        }),
        g.panel.table.queryOptions.transformation.withId("calculateField")
        + g.panel.table.queryOptions.transformation.withOptions({
          alias: "week_index",
          binary: {
            left: "count",
            right: "1"
          },
          mode: "binary",
          reduce: {
            reducer: "sum"
          }
        }),
        g.panel.table.queryOptions.transformation.withId("organize")
        + g.panel.table.queryOptions.transformation.withOptions({
          excludeByName: {
            count: true
          },
          includeByName: {},
          indexByName: {},
          renameByName: {
            "Trend #blocker count": "blockers_count",
            "Trend #gprd hours blocked": "gprd_hours_blocked",
            "Trend #gstg hours blocked": "gstg_hours_blocked"
          }
        })
      ])
  },
};

basic.dashboard(
  'Deployment Blockers',
  tags=['release'],
  editable=true,
  time_from='now-90d',
  time_to='now',
  includeStandardEnvironmentAnnotations=false,
  includeEnvironmentTemplate=false,
  defaultDatasource=mimirHelper.mimirDatasource('gitlab-ops'),
)
.addTemplate(
  template.new(
    'root_cause',
    '$PROMETHEUS_DS',
    'label_values(delivery_deployment_blocker_count{root_cause!="RootCause::FlakyTest"},root_cause)',
    includeAll=true,
    multi=true,
  )
)
.addRow(
  row.new(
    title='Overview',
    height='250px',
  )
  .addPanel(
    panels.text.textPanel(''), gridPos={ x: 0, y: 1, w: 24, h: 7 }
  )
  .addPanel(
    panels.barChart.barChartPanel('', queries.totalBlockersCount), gridPos={ x: 0, y: 8, w: 8, h: 10 }
  )
  .addPanel(
    panels.barChart.barChartPanel('', queries.totalGprdHoursBlocked), gridPos={ x: 8, y: 8, w: 8, h: 10 }
  )
  .addPanel(
    panels.barChart.barChartPanel('', queries.totalGstgHoursBlocked), gridPos={ x: 16, y: 8, w: 8, h: 10 }
  )
)
.addRow(
  row.new(
    title='$root_cause',
    repeat='root_cause',
    height='250px',
  )
  .addPanel(
    panels.trend.trendPanel('Blockers Count for $root_cause', queries.blockersCount('$root_cause')), gridPos={ x: 0, y: 19, w: 8, h: 8 }
  )
  .addPanel(
    panels.trend.trendPanel('gprd Hours Blocked for $root_cause', queries.gprdHoursBlocked('$root_cause')), gridPos={ x: 8, y: 19, w: 8, h: 8 }
  )
  .addPanel(
    panels.trend.trendPanel('gstg Hours Blocked for $root_cause', queries.gstgHoursBlocked('$root_cause')), gridPos={ x: 16, y: 19, w: 8, h: 8 }
  )
  .addPanel(
    panels.table.tablePanel('', queries.tabulatedDeploymentBlockers('$root_cause')), gridPos={ x: 0, y: 27, w: 24, h: 8 }
  )
)
.trailer()
