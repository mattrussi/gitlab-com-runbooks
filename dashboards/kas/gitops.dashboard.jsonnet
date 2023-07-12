local basic = import 'grafana/basic.libsonnet';
local layout = import 'grafana/layout.libsonnet';
local templates = import 'grafana/templates.libsonnet';
local selectors = import 'promql/selectors.libsonnet';

local selector = { env: '$environment', stage: '$stage', type: 'kas' };
local selectorString = selectors.serializeHash(selector);

basic.dashboard(
  'GitOps metrics',
  tags=[
    'kas',
  ],
)
.addTemplate(templates.stage)
.addPanels(
  layout.grid([
    basic.timeseries(
      title='Flux: Git push notifications sent',
      description='The total number of sent Git Push notifications to agentks in Flux module',
      query=|||
        sum (increase(flux_git_push_notifications_total{%s}[$__rate_interval]))
      ||| % selectorString,
      yAxisLabel='times',
      legend_show=false,
    ),
    basic.timeseries(
      title='Flux: Git push notifications dropped',
      description='The total number of dropped Git push notifications in Flux module',
      query=|||
        sum (increase(flux_dropped_git_push_notifications_total{%s}[$__rate_interval]))
      ||| % selectorString,
      yAxisLabel='times',
      legend_show=false,
    ),
  ], cols=2, rowHeight=10)
)
