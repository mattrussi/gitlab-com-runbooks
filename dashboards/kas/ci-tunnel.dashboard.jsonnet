local basic = import 'grafana/basic.libsonnet';
local layout = import 'grafana/layout.libsonnet';
local templates = import 'grafana/templates.libsonnet';
local selectors = import 'promql/selectors.libsonnet';

local selector = { env: '$environment', stage: '$stage', type: 'kas' };
local selectorString = selectors.serializeHash(selector);

basic.dashboard(
  'CI tunnel',
  tags=[
    'kas',
  ],
)
.addTemplate(templates.stage)
.addPanels(
  layout.grid([
    basic.heatmap(
      title='Routing latency (success)',
      description='Time it takes kas to find a suitable reverse tunnel from an agent',
      query='sum by (le) (rate(tunnel_routing_duration_seconds_bucket{%s, status="success"}[$__rate_interval]))' % selectorString,
      dataFormat='tsbuckets',
      color_cardColor='#00ff00',
      legendFormat='__auto',
    ),
    basic.heatmap(
      title='Routing latency (request aborted)',
      description='Time it takes kas to find a suitable reverse tunnel from an agent',
      query='sum by (le) (rate(tunnel_routing_duration_seconds_bucket{%s, status="aborted"}[$__rate_interval]))' % selectorString,
      dataFormat='tsbuckets',
      color_cardColor='#0000ff',
      legendFormat='__auto',
    ),
    basic.timeseries(
      title='Routing request timed out',
      description='CI tunnel request routing took longer than 20s',
      query=|||
        sum (increase(tunnel_routing_timeout_total{%s}[$__rate_interval]))
      ||| % selectorString,
      yAxisLabel='requests',
      legend_show=false,
    ),
    basic.timeseries(
      title='OK gRPC calls/second',
      description='OK gRPC calls related to CI tunnel',
      query=|||
        sum by (grpc_service, grpc_method) (
          rate(grpc_server_handled_total{%s, grpc_code="OK",
            grpc_service=~"gitlab.agent.reverse_tunnel.rpc.ReverseTunnel|gitlab.agent.kubernetes_api.rpc.KubernetesApi"
          }[$__rate_interval])
        )
      ||| % selectorString,
      legendFormat='{{grpc_service}}/{{grpc_method}}',
      yAxisLabel='rps',
      linewidth=1,
    ),
    basic.timeseries(
      title='Not OK gRPC calls/second',
      description='Not OK gRPC calls related to CI tunnel',
      query=|||
        sum by (grpc_service, grpc_method, grpc_code) (
          rate(grpc_server_handled_total{%s, grpc_code!="OK",
            grpc_service=~"gitlab.agent.reverse_tunnel.rpc.ReverseTunnel|gitlab.agent.kubernetes_api.rpc.KubernetesApi"
          }[$__rate_interval])
        )
      ||| % selectorString,
      legendFormat='{{grpc_service}}/{{grpc_method}} {{grpc_code}}',
      yAxisLabel='rps',
      linewidth=1,
    ),
  ], cols=3, rowHeight=10)
)
