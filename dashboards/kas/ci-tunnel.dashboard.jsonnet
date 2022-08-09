local basic = import 'grafana/basic.libsonnet';
local layout = import 'grafana/layout.libsonnet';
local templates = import 'grafana/templates.libsonnet';

local env_stage_app = 'env="$environment", stage="$stage", app="kas"';

basic.dashboard(
  'CI tunnel',
  tags=[
    'kas',
  ],
)
.addTemplate(templates.stage)
.addPanels(
  layout.singleRow([
    basic.heatmap(
      title='Routing latency',
      description='Time it takes kas to find a suitable reverse tunnel from an agent',
      query='sum by (le) (rate(k8s_api_proxy_routing_duration_seconds_bucket{%s}[$__rate_interval]))' % env_stage_app,
      dataFormat='tsbuckets',
      legendFormat='__auto',
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
      ||| % env_stage_app,
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
      ||| % env_stage_app,
      legendFormat='{{grpc_service}}/{{grpc_method}} {{grpc_code}}',
      yAxisLabel='rps',
      linewidth=1,
    ),
  ], rowHeight=10)
)
