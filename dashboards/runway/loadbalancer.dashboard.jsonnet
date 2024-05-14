local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local basic = import 'grafana/basic.libsonnet';
local layout = import 'grafana/layout.libsonnet';
local selectors = import 'promql/selectors.libsonnet';
local template = grafana.template;
local mimirHelper = import 'services/lib/mimir-helpers.libsonnet';

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
  defaultDatasource=mimirHelper.mimirDatasource('Runway')
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
        title='Request rate by status',
        description='Rate of requests served by the external HTTP(S) load balancer, grouped by HTTP status code.',
        yAxisLabel='Requests per Second',
        query=|||
          sum by(response_code_class) (
            rate(
              stackdriver_https_lb_rule_loadbalancing_googleapis_com_https_request_count{%(selector)s}[$__rate_interval]
            )
          )
        ||| % formatConfig,
        legendFormat='HTTP status {{response_code_class}}',
        decimals=2,
        intervalFactor=2,
      ),
      basic.timeseries(
        title='Request rate by region',
        description='Rate of requests served by the external HTTP(S) load balancer, grouped by the region of the backend handling the request.',
        yAxisLabel='Requests per Second',
        query=|||
          sum by(backend_scope) (
            rate(
              stackdriver_https_lb_rule_loadbalancing_googleapis_com_https_request_count{%(selector)s}[$__rate_interval]
            )
          )
        ||| % formatConfig,
        legendFormat='Region {{backend_scope}}',
        decimals=2,
        intervalFactor=2,
      ),
      basic.percentageTimeseries(
        title='Error ratio',
        description='Ratio of HTTP 5xx status codes to total number of requests.',
        yAxisLabel='Error ratio',
        query=|||
          rate(
            stackdriver_https_lb_rule_loadbalancing_googleapis_com_https_request_count{response_code_class="500",%(selector)s}[$__rate_interval]
          )
          /
          rate(
            stackdriver_https_lb_rule_loadbalancing_googleapis_com_https_request_count{%(selector)s}[$__rate_interval]
          )
          OR on()
          vector(0)
        ||| % formatConfig,
        legendFormat='Total error ratio',
        decimals=2,
        intervalFactor=2,
      ),
      basic.timeseries(
        title='Error rate by region',
        description='Rate of requests with status code 500 served by the external HTTP(S) load balancer, grouped by the region of the backend handling the request.',
        yAxisLabel='Requests per Second',
        query=|||
          sum by(backend_scope) (
            rate(
              stackdriver_https_lb_rule_loadbalancing_googleapis_com_https_request_count{response_code_class="500",%(selector)s}[$__rate_interval]
            )
          )
        ||| % formatConfig,
        legendFormat='Region {{backend_scope}}',
        decimals=2,
        intervalFactor=2,
      ),
      basic.latencyTimeseries(
        title='Total latency by region',
        description='The latency calculated from when the request was received by the external HTTP(S) load balancer proxy until the proxy got ACK from client on last response byte.',
        yAxisLabel='Duration',
        query=|||
          histogram_quantile(
            0.99,
            sum by(le, backend_scope) (
              rate(stackdriver_https_lb_rule_loadbalancing_googleapis_com_https_total_latencies_bucket{%(selector)s}[$__rate_interval])
            )
          )
        ||| % formatConfig,
        format='ms',
        legendFormat='Region {{backend_scope}} p99',
        intervalFactor=2,
      ),
      basic.latencyTimeseries(
        title='Backend latency by region',
        description='Distribution of the latency calculated from when the request was sent by the proxy to the backend, in milliseconds.',
        yAxisLabel='Duration',
        query=|||
          histogram_quantile(
            0.99,
            sum by(le, backend_scope) (
              rate(stackdriver_https_lb_rule_loadbalancing_googleapis_com_https_backend_latencies_bucket{%(selector)s}[$__rate_interval])
            )
          )
        ||| % formatConfig,
        format='ms',
        legendFormat='Region {{backend_scope}} p99',
        intervalFactor=2,
      ),
    ]
  )
)
