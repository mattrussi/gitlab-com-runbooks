local basic = import 'grafana/basic.libsonnet';
local layout = import 'grafana/layout.libsonnet';
local templates = import 'grafana/templates.libsonnet';
local selectors = import 'promql/selectors.libsonnet';

local selector = { env: '$environment', stage: '$stage', type: 'kas' };
local selectorString = selectors.serializeHash(selector);

basic.dashboard(
  'Miscellaneous metrics',
  tags=[
    'kas',
  ],
)
.addTemplate(templates.stage)
.addPanels(
  layout.grid([
    basic.timeseries(
      title='OK gRPC calls/second',
      description='OK gRPC calls',
      query=|||
        sum by (grpc_service, grpc_method) (
          rate(grpc_server_handled_total{%s, grpc_code="OK"}[$__rate_interval])
        )
      ||| % selectorString,
      legendFormat='{{grpc_service}}/{{grpc_method}}',
      yAxisLabel='rps',
      linewidth=1,
    ),
    basic.timeseries(
      title='Not OK gRPC calls/second',
      description='Not OK gRPC calls',
      query=|||
        sum by (grpc_service, grpc_method, grpc_code) (
          rate(grpc_server_handled_total{%s, grpc_code!="OK"}[$__rate_interval])
        )
      ||| % selectorString,
      legendFormat='{{grpc_service}}/{{grpc_method}} {{grpc_code}}',
      yAxisLabel='rps',
      linewidth=1,
    ),
    basic.timeseries(
      title='Agent connections rate limit exceeded',
      description='The total number of times configured rate limit of new agent connections was exceeded',
      query=|||
        sum (increase(agent_server_rate_exceeded_total{%s}[$__rate_interval]))
      ||| % selectorString,
      yAxisLabel='times',
      legend_show=false,
      linewidth=1,
    ),
  ], cols=2, rowHeight=10)
)
