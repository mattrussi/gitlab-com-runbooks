local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local basic = import 'grafana/basic.libsonnet';
local promQuery = import 'grafana/prom_query.libsonnet';
local seriesOverrides = import 'grafana/series_overrides.libsonnet';
local row = grafana.row;
local layout = import 'grafana/layout.libsonnet';
local text = grafana.text;
local issueSearch = import './issue_search.libsonnet';
local utilizationResources = import 'servicemetrics/utilization-metrics.libsonnet';
local selectors = import 'promql/selectors.libsonnet';

local maxOverTime(query) =
  'max_over_time(%(query)s[$__interval])' % { query: query };

{
  utilizationPanel(title, description, component, componentDetails, linewidth=1, legendFormat=null, selector=null, overTimeFunction=maxOverTime)::
    local formatConfig = {
      component: component,
      recordingRuleName: componentDetails.getRecordingRuleName(component),
      selector: selectors.serializeHash(selector),
    };

    local panel = basic.graphPanel(
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
      stableId='utilization-' + component,
    );

    local recordingRuleQuery = '%(recordingRuleName)s{%(selector)s}' % formatConfig;

    local recordingRuleQueryWithTimeFunction = if overTimeFunction != null then
      overTimeFunction(recordingRuleQuery)
    else
      recordingRuleQuery;

    panel.addTarget(  // Primary metric
      promQuery.target(
        |||
              max(
                %(recordingRuleQueryWithTimeFunction)s
              ) by (component)
        ||| % formatConfig {
          recordingRuleQueryWithTimeFunction: recordingRuleQueryWithTimeFunction,
        },
        legendFormat='{{ component }}',
      )
    )
    .resetYaxes()
    .addYaxis(
      format=componentDetails.unit,
      label='Utilization %s' % componentDetails.unit,
    ) {
      legend+: {
        sort: 'max',
        sortDesc: true,
      },
    },


  componentUtilizationPanel(component, selectorHash)::
    local componentDetails = utilizationResources[component];

    self.utilizationPanel(
      '%s component utilization: %s' % [component, componentDetails.title],
      description=componentDetails.description + ' Lower is better.',
      component=component,
      componentDetails=componentDetails,
      linewidth=1,
      legendFormat=componentDetails.getLegendFormat(),
      selector=selectorHash,
    ),

  utilizationDetailPanels(selectorHash, components)::
    row.new(title='📈 Utilization Details', collapse=true)
    .addPanels(layout.grid([
      self.componentUtilizationPanel(component, selectorHash)
      for component in components
    ])),

  componentUtilizationHelpPanel(component)::
    local componentDetails = utilizationResources[component];

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
