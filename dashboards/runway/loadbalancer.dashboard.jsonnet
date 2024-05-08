local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local basic = import 'grafana/basic.libsonnet';
local layout = import 'grafana/layout.libsonnet';
local selectors = import 'promql/selectors.libsonnet';
local template = grafana.template;

local formatConfig = {
  selector: selectors.serializeHash({
    job: 'runway-exporter',
    env: '$environment',
    url_map_name: '$loadbalancer',
    backend_scope: { re: '$region' },
  }),
};

basic.dashboard(
  'Runway Load Balancer Metrics',
  tags=['runway', 'type:runway'],
  includeStandardEnvironmentAnnotations=false,
)
.addTemplate(template.new(
  'loadbalancer',
  '$PROMETHEUS_DS',
  'label_values(stackdriver_https_lb_rule_loadbalancing_googleapis_com_https_backend_request_count{job="runway-exporter", env="$environment"}, url_map_name)',
  refresh='load',
  sort=1,
))
.addTemplate(template.new(
  'region',
  '$PROMETHEUS_DS',
  'label_values(stackdriver_https_lb_rule_loadbalancing_googleapis_com_https_backend_request_count{job="runway-exporter", env="$environment", url_map_name="$loadbalancer"}, backend_scope)',
  refresh='load',
  sort=1,
  includeAll=true,
  allValues='.+',
))
.addPanels(
  layout.grid(
    [
      basic.timeseries(
        title='Request rate',
        description='Rate of requests served by backends of external HTTP(S) load balancer.',
        yAxisLabel='Requests per Second',
        query=|||
          sum by (response_code_class, backend_scope) (
            rate(
              stackdriver_https_lb_rule_loadbalancing_googleapis_com_https_backend_request_count{%(selector)s}[$__rate_interval]
            )
          )
        ||| % formatConfig,
        legendFormat='{{response_code_class}} {{backend_scope}}',
        intervalFactor=2,
      ),
      basic.latencyTimeseries(
        title='Request latency',
        description='Distribution of the latency calculated from when the request was sent by the proxy to the backend, in milliseconds.',
        yAxisLabel='Duration',
        query=|||
          histogram_quantile(
            0.99,
            sum by (revision_name, le, backend_scope) (
              rate(stackdriver_https_lb_rule_loadbalancing_googleapis_com_https_backend_latencies_bucket{%(selector)s}[$__rate_interval])
            )
          )
        ||| % formatConfig,
        format='ms',
        legendFormat='p99 {{revision_name}} {{backend_scope}}',
        intervalFactor=2,
      ),
    ]
  )
)
