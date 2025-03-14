local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local basic = import 'grafana/basic.libsonnet';
local promQuery = import 'grafana/prom_query.libsonnet';
local seriesOverrides = import 'grafana/series_overrides.libsonnet';
local row = grafana.row;
local layout = import 'grafana/layout.libsonnet';
local text = grafana.text;
local issueSearch = import './issue_search.libsonnet';
local saturationResources = import 'servicemetrics/saturation-resources.libsonnet';
local selectors = import 'promql/selectors.libsonnet';
local panels = import './key-metric-panels/time-series/panels.libsonnet';
local panel = import 'grafana/time-series/panel.libsonnet';
local target = import 'grafana/time-series/target.libsonnet';
local override = import 'grafana/time-series/override.libsonnet';

local maxOverTime(query) =
  'max_over_time(%(query)s[$__interval])' % { query: query };

{
  saturationPanel(title, description, component, linewidth=1, query=null, legendFormat=null, selector=null, overTimeFunction=maxOverTime, useTimeSeriesPlugin=false)::
    local formatConfig = {
      component: component,
      query: query,
      selector: selectors.serializeHash(selector),
    };

    local p1 =
      if useTimeSeriesPlugin then
        panel.basic(
          title=title,
          description=description,
          linewidth=linewidth,
          unit='percentunit',
          legend_show=true,
        )
      else
        basic.graphPanel(
          title=title,
          description=description,
          sort='decreasing',
          linewidth=linewidth,
          fill=0,
          datasource='$PROMETHEUS_DS',
          decimals=2,
          legend_show=true,
          legend_values=true,
          legend_min=true,
          legend_max=true,
          legend_current=true,
          legend_total=false,
          legend_avg=true,
          legend_alignAsTable=true,
          legend_hideEmpty=true,
          stableId='saturation-' + component,
        );

    local p2 =
      if query != null then
        if useTimeSeriesPlugin then
          panel.addTarget(  // Primary metric
            target.prometheus(
              |||
                clamp_min(
                  clamp_max(
                    %(query)s
                  ,1)
                ,0)
              ||| % formatConfig,
              legendFormat=legendFormat,
            )
          )
        else
          p1.addTarget(  // Primary metric
            promQuery.target(
              |||
                clamp_min(
                  clamp_max(
                    %(query)s
                  ,1)
                ,0)
              ||| % formatConfig,
              legendFormat=legendFormat,
            )
          )
      else
        p1;

    local recordingRuleQuery = 'gitlab_component_saturation:ratio{%(selector)s, component="%(component)s"}' % formatConfig;

    local recordingRuleQueryWithTimeFunction = if overTimeFunction != null then
      overTimeFunction(recordingRuleQuery)
    else
      recordingRuleQuery;

    if useTimeSeriesPlugin then
      p2.addTarget(  // Primary metric
        target.prometheus(
          |||
            clamp_min(
              clamp_max(
                max(
                  %(recordingRuleQueryWithTimeFunction)s
                ) by (component)
              ,1)
            ,0)
          ||| % formatConfig { recordingRuleQueryWithTimeFunction: recordingRuleQueryWithTimeFunction },
          legendFormat='aggregated {{ component }}',
        )
      )
      .addTarget(  // 95th quantile for week
        target.prometheus(
          |||
            max(
              gitlab_component_saturation:ratio_quantile95_1w{%(selector)s, component="%(component)s"}
            )
          ||| % formatConfig,
          legendFormat='95th quantile for week {{ component }}',
        )
      )
      .addTarget(  // 99th quantile for week
        target.prometheus(
          |||
            max(
              gitlab_component_saturation:ratio_quantile99_1w{%(selector)s, component="%(component)s"}
            )
          ||| % formatConfig,
          legendFormat='99th quantile for week {{ component }}',
        )
      )
      .addTarget(  // Soft SLO
        target.prometheus(
          |||
            avg(slo:max:soft:gitlab_component_saturation:ratio{component="%(component)s"}) by (component)
          ||| % formatConfig,
          legendFormat='Soft SLO: {{ component }}',
        )
      )
      .addTarget(  // Hard SLO
        target.prometheus(
          |||
            avg(slo:max:hard:gitlab_component_saturation:ratio{component="%(component)s"}) by (component)
          ||| % formatConfig,
          legendFormat='Hard SLO: {{ component }}',
        )
      )
      .addYaxis(
        max=1,
        label='Saturation %',
      )
      .addSeriesOverride(override.softSlo)
      .addSeriesOverride(override.hardSlo)
      .addSeriesOverride(override.goldenMetric('/aggregated /', { linewidth: 2 },))
      .addSeriesOverride({
        alias: '/^95th quantile for week/',
        color: '#37872D',
        dashes: true,
        legend: true,
        linewidth: 1,
        dashLength: 4,
        nullPointMode: 'connected',

      })
      .addSeriesOverride({
        alias: '/^99th quantile for week/',
        color: '#56A64B',
        dashes: true,
        legend: true,
        linewidth: 2,
        dashLength: 4,
        nullPointMode: 'connected',
      }) {
        legend+: {
          sort: 'max',
          sortDesc: true,
        },
      }
    else
      p2.addTarget(  // Primary metric
        promQuery.target(
          |||
            clamp_min(
              clamp_max(
                max(
                  %(recordingRuleQueryWithTimeFunction)s
                ) by (component)
              ,1)
            ,0)
          ||| % formatConfig { recordingRuleQueryWithTimeFunction: recordingRuleQueryWithTimeFunction },
          legendFormat='aggregated {{ component }}',
        )
      )
      .addTarget(  // 95th quantile for week
        promQuery.target(
          |||
            max(
              gitlab_component_saturation:ratio_quantile95_1w{%(selector)s, component="%(component)s"}
            )
          ||| % formatConfig,
          legendFormat='95th quantile for week {{ component }}',
        )
      )
      .addTarget(  // 99th quantile for week
        promQuery.target(
          |||
            max(
              gitlab_component_saturation:ratio_quantile99_1w{%(selector)s, component="%(component)s"}
            )
          ||| % formatConfig,
          legendFormat='99th quantile for week {{ component }}',
        )
      )
      .addTarget(  // Soft SLO
        promQuery.target(
          |||
            avg(slo:max:soft:gitlab_component_saturation:ratio{component="%(component)s"}) by (component)
          ||| % formatConfig,
          legendFormat='Soft SLO: {{ component }}',
        )
      )
      .addTarget(  // Hard SLO
        promQuery.target(
          |||
            avg(slo:max:hard:gitlab_component_saturation:ratio{component="%(component)s"}) by (component)
          ||| % formatConfig,
          legendFormat='Hard SLO: {{ component }}',
        )
      )
      .resetYaxes()
      .addYaxis(
        format='percentunit',
        max=1,
        label='Saturation %',
      )
      .addYaxis(
        format='short',
        max=1,
        min=0,
        show=false,
      )
      .addSeriesOverride(seriesOverrides.softSlo)
      .addSeriesOverride(seriesOverrides.hardSlo)
      .addSeriesOverride(seriesOverrides.goldenMetric('/aggregated /', { linewidth: 2 },))
      .addSeriesOverride({
        alias: '/^95th quantile for week/',
        color: '#37872D',
        dashes: true,
        legend: true,
        lines: true,
        linewidth: 1,
        dashLength: 4,
        spaceLength: 10,
        nullPointMode: 'connected',
        zindex: -2,

      })
      .addSeriesOverride({
        alias: '/^99th quantile for week/',
        color: '#56A64B',
        dashes: true,
        legend: true,
        lines: true,
        linewidth: 2,
        dashLength: 4,
        spaceLength: 4,
        nullPointMode: 'connected',
        zindex: -2,
      }) {
        legend+: {
          sort: 'max',
          sortDesc: true,
        },
      },


  componentSaturationPanel(component, selectorHash, useTimeSeriesPlugin=false)::
    local componentDetails = saturationResources[component];
    local query = componentDetails.getQuery(selectorHash, componentDetails.getBurnRatePeriod(), maxAggregationLabels=componentDetails.resourceLabels);

    if useTimeSeriesPlugin then
      panels.saturationDetail(
        '%s component saturation: %s' % [component, componentDetails.title],
        description=componentDetails.description + ' Lower is better.',
        component=component,
        linewidth=1,
        query=query,
        legendFormat=componentDetails.getLegendFormat(),
        selector=selectorHash,
      )
    else
      self.saturationPanel(
        '%s component saturation: %s' % [component, componentDetails.title],
        description=componentDetails.description + ' Lower is better.',
        component=component,
        linewidth=1,
        query=query,
        legendFormat=componentDetails.getLegendFormat(),
        selector=selectorHash,
      ),

  saturationDetailPanels(selectorHash, components, useTimeSeriesPlugin=false)::
    row.new(title='🌡 Saturation Details', collapse=true)
    .addPanels(layout.grid([
      self.componentSaturationPanel(component, selectorHash, useTimeSeriesPlugin)
      for component in components
    ])),

  componentSaturationHelpPanel(component)::
    local componentDetails = saturationResources[component];

    text.new(
      title='Help',
      mode='markdown',
      content=|||
        ## %(title)s

        %(description)s

        ## What to do from here?

        * Check the ${type} service overview dashboard (accessible from the menu above)
        * [Find related issues on GitLab.com](%(issueSearchLink)s)
        * [Create an issue in the Infrastructure Tracker](%(createIssueLink)s)

        Keep in mind that this is a **causal alert**. This means that this may not neccessarily
        be leading to user impact. Check the alert list below for active symptom based
        alerts incidating potential user impact.
      ||| % {
        title: componentDetails.title,
        description: componentDetails.description,
        issueSearchLink: issueSearch.buildInfraIssueSearch(labels=['GitLab.com Resource Saturation'], search=component),
        createIssueLink: 'https://gitlab.com/gitlab-com/gl-infra/reliability/-/issues/new?issue[title]=Resource+Saturation:+%s&issue[description]=/label+~"GitLab.com+Resource+Saturation"' % [component],
      }
    ),
}
