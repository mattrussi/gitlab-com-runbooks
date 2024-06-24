local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local g = import 'github.com/grafana/grafonnet/gen/grafonnet-latest/main.libsonnet';
local prometheusQuery = g.query.prometheus;
local row = g.panel.row;
local var = g.dashboard.variable;

local variables = {
  datasource: var.datasource.new('datasource', '$PROMETHEUS_DS'),

  root_cause: (
    var.query.new('root_cause') +
    var.query.withDatasourceFromVariable(self.datasource) +
    var.query.queryTypes.withLabelValues(
      'delivery_deployment_blocker_count{root_cause!="RootCause::FlakyTest"}',
      'root_cause'
    ) +
    var.query.selectionOptions.withMulti() +
    var.query.selectionOptions.withIncludeAll()
  )
};

local queries = {
  totalBlockersCount:
    prometheusQuery.new(
      '$' + variables.datasource.name,
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
    + prometheusQuery.withInterval(2d)
    + prometheusQuery.withFormat("time_series"),

  totalGprdHoursBlocked:
    prometheusQuery.new(
      '$' + variables.datasource.name,
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
    + prometheusQuery.withInterval(2d)
    + prometheusQuery.withFormat("time_series"),

  totalGstgHoursBlocked:
    prometheusQuery.new(
      '$' + variables.datasource.name,
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
    + prometheusQuery.withInterval(2d)
    + prometheusQuery.withFormat("time_series"),

  blockersCount:
    prometheusQuery.new(
      '$' + variables.datasource.name,
      |||
        max by(week) (
          last_over_time(
            delivery_deployment_blocker_count{
              root_cause="$root_cause"
              }
            [1d])
        )
      |||
    )
    + prometheusQuery.withInterval(2d)
    + prometheusQuery.withFormat("table"),

  gprdHoursBlocked:
    prometheusQuery.new(
      '$' + variables.datasource.name,
      |||
        max by(week) (
          last_over_time(
            delivery_deployment_blocker_count{
              root_cause="$root_cause"
              }
            [1d])
        )
      |||
    )
    + prometheusQuery.withInterval(2d)
    + prometheusQuery.withFormat("table"),

  gstgHoursBlocked:
    prometheusQuery.new(
      '$' + variables.datasource.name,
      |||
        max by(week) (
          last_over_time(
            delivery_deployment_hours_blocked{
              root_cause="$root_cause",
              target_env="gstg"
              }
            [1d])
        )
      |||
    )
    + prometheusQuery.withInterval(2d)
    + prometheusQuery.withFormat("table"),

  tabulatedDeploymentBlockers:
    [
      prometheusQuery.new(
        '$' + variables.datasource.name,
        |||
          max by(week) (
            last_over_time(
              delivery_deployment_blocker_count{
                root_cause=\"$root_cause\"
                }
              [1d])
          )
        |||
      )
      + prometheusQuery.withInterval(2d)
      + prometheusQuery.withFormat("time_series"),
    ] + [
      prometheusQuery.new(
        '$' + variables.datasource.name,
        |||
          max by(week) (
            last_over_time(
              delivery_deployment_hours_blocked{
                root_cause=\"$root_cause\",
                target_env=\"gprd\"}
              [1d])
            )
        |||
      )
      + prometheusQuery.withInterval(2d)
      + prometheusQuery.withFormat("time_series"),
    ] + [
      prometheusQuery.new(
        '$' + variables.datasource.name,
        |||
          max by(week) (
            last_over_time(
              delivery_deployment_hours_blocked{
                root_cause=\"$root_cause\",
                target_env=\"gstg\"}
              [1d])
            )
        |||
      )
      + prometheusQuery.withInterval(2d)
      + prometheusQuery.withFormat("time_series"),
    ],
};

local panels = {
  text: {
    local text = g.panel.text,
    local options = text.options,

    textPanel:
      text.new('')
      + options.withMode("markdown")
      + options.withContent('''
        # Deployment Blockers

        Deployment failures are currently automatically captured under [release/tasks issues](https://gitlab.com/gitlab-org/release/tasks/-/issues).
        Release managers are responsible for labeling these failures with appropriate `RootCause::*` labels. By the start of the following week (Monday), the `deployments:blockers_report` scheduled pipeline in the [release/tools](https://ops.gitlab.net/gitlab-org/release/tools/-/pipeline_schedules) repo reviews the labeled issues and generates a weekly deployment blockers issue, like this [one](https://gitlab.com/gitlab-org/release/tasks/-/issues/11125).

        This dashboard tracks the trend of recurring root causes for deployment blockers. Each root cause is displayed in separate rows with three panels: one for the count of blockers, one for `gprd` hours blocked, and one for `gstg` hours blocked. At the top, there is an overview of the failure types, including the total calculations for the entire specified time window.

        Links:
        - [List of root causes](https://gitlab.com/gitlab-org/release/tasks/-/labels?subscribed=&sort=relevance&search=RootCause)
        - [Deployments metrics review](https://gitlab.com/groups/gitlab-com/gl-infra/-/epics/1192)
      ''')
      + text.panelOptions.withGridPos(h=7, w=24, x=0, y=1)
  },

  barChart: {
    local barChart = g.panel.barChart,
    local options = barChart.options,
    local standardOptions = barChart.standardOptions,
    local queryOptions = barChart.queryOptions,

    barChartPanel: function(targets) {
      barChart.new('')
      + queryOptions.withTargets(targets)
      + queryOptions.withInterval('2d')
      + options.withOrientation("horizontal")
      + options.legend.withDisplayMode('table')
      + options.legend.withPlacement("bottom")
      + options.legend.withCalcs(['total'])
      + standardOptions.withDisplayName("blockers_count")
      + standardOptions.color.withMode("thresholds")
      + queryOptions.withTransformations([
        queryOptions.transformation.withId("reduce")
        + queryOptions.transformation.withOptions({ reducers: ['sum'] })
      ])
    }
  },

  trend: {
    local trend = g.panel.trend,
    local custom = trend.fieldConfig.defaults.custom,
    local options = trend.options,
    local standardOptions = trend.standardOptions,
    local queryOptions = trend.queryOptions,

    trendPanel: function(title, targets) {
      trend.new(title)
      + queryOptions.withTargets(targets)
      + queryOptions.withInterval('2d')
      + options.withXField("week_index")
      + options.legend.withDisplayMode('list')
      + options.legend.withPlacement("bottom")
      + custom.withDrawStyle("line")
      + custom.withLineInterpolation("linear")
      + custom.withLineWidth(1)
      + custom.withShowPoints("always")
      + custom.withSpanNulls(true)
      + custom.withAxisBorderShow(true)
      + custom.withAxisSoftMin(1)
      + standardOptions.withDecimals(0)
      + standardOptions.withUnit("short")
      + standardOptions.withMin(1)
      + standardOptions.color.withMode("palette-classic")
      + standardOptions.withOverrides([
        standardOptions.override.byName.new('week_index')
        + standardOptions.override.byName.withPropertiesFromOptions(
          custom.withAxisLabel("week_index")
          + custom.withAxisPlacement("hidden")
        )
      ])
      + queryOptions.withTransformations([
        queryOptions.transformation.withId("calculateField")
        + queryOptions.transformation.withOptions({
          alias: "count",
          binary: {
            left: "week"
          },
          mode: "index",
          reduce: {
            reducer: "sum"
          }
        }),
        queryOptions.transformation.withId("calculateField")
        + queryOptions.transformation.withOptions({
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
        queryOptions.transformation.withId("organize")
        + queryOptions.transformation.withOptions({
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
    }
  },

  table: {
    local table = g.panel.table,
    local custom = table.fieldConfig.defaults.custom,
    local options = table.options,
    local standardOptions = table.standardOptions,
    local queryOptions = table.queryOptions,

    tablePanel: function(targets) {
      table.new('')
      + queryOptions.withTargets(targets)
      + queryOptions.withInterval('2d')
      + custom.withFilterable(true)
      + custom.withDisplayMode("auto")
      + options.withShowHeader(true)
      + standardOptions.color.withMode("thresholds")
      + queryOptions.withTransformations([
        queryOptions.transformation.withId("timeSeriesTable")
        + queryOptions.transformation.withOptions({}),
        queryOptions.transformation.withId("merge")
        + queryOptions.transformation.withOptions({}),
        queryOptions.transformation.withId("calculateField")
        + queryOptions.transformation.withOptions({
          alias: "count",
          mode: "index",
          reduce: {
            reducer: "sum"
          }
        }),
        queryOptions.transformation.withId("calculateField")
        + queryOptions.transformation.withOptions({
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
        queryOptions.transformation.withId("organize")
        + queryOptions.transformation.withOptions({
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
      + table.panelOptions.withGridPos(h=8, w=24, x=0, y=8)
    }
  }
};

g.dashboard.new('Deployment Blockers')
+ g.dashboard.withVariables([
  variables.datasource,
  variables.root_cause,
])
+ g.dashboard.withPanels(
  row.new('Overview')
  + row.withCollapsed(false)
  + row.withPanels([
    panels.text.textPanel,
    g.util.grid.makeGrid([
      panels.barChart.barChartPanel(queries.totalBlockersCount),
      panels.barChart.barChartPanel(queries.totalGprdHoursBlocked),
      panels.barChart.barChartPanel(queries.totalGstgHoursBlocked),
    ], panelWidth=8),
  ]),
  row.new('$root_cause')
  + row.withRepeat('$root_cause')
  + row.withCollapsed(true)
  + row.withPanels([
    g.util.grid.makeGrid([
      panels.trend.trendPanel('Blockers Count for $root_cause', queries.blockersCount),
      panels.trend.trendPanel('gprd Hours Blocked for $root_cause', queries.gprdHoursBlocked),
      panels.trend.trendPanel('gstg Hours Blocked for $root_cause', queries.gstgHoursBlocked),
    ]),
    panels.table.tablePanel(queries.tabulatedDeploymentBlockers),
  ], panelWidth=8),
)
.trailer()
