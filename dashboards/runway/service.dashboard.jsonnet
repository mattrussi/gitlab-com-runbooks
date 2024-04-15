local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local basic = import 'grafana/basic.libsonnet';
local layout = import 'grafana/layout.libsonnet';
local selectors = import 'promql/selectors.libsonnet';
local template = grafana.template;
local commonAnnotations = import 'grafana/common_annotations.libsonnet';

// This dashboard currently shows both the `{{region}}` and `{{location}}` label.
// We do this because in Thanos the `region` label on metrics gets overridden by
// the external_label advertised by Prometheus.
// This does not happen in Mimir, so when the migration is complete we can remove
// references to the location label
// https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/3398

local formatConfig = {
  selector: selectors.serializeHash({ job: 'runway-exporter', env: '$environment', type: '$type', location: { re: '$region' } }),
};

basic.dashboard(
  'Runway Service Metrics',
  tags=['runway', 'type:runway'],
  includeStandardEnvironmentAnnotations=false,
)
.addTemplate(template.new(
  'type',
  '$PROMETHEUS_DS',
  'label_values(stackdriver_cloud_run_revision_run_googleapis_com_container_instance_count{job="runway-exporter", env="$environment"}, service_name)',
  label='service',
  refresh='load',
  sort=1,
))
.addTemplate(template.new(
  'region',
  '$PROMETHEUS_DS',
  'label_values(stackdriver_cloud_run_revision_run_googleapis_com_container_instance_count{job="runway-exporter", env="$environment", type="$type"}, location)',
  refresh='load',
  sort=1,
  includeAll=true,
  allValues='.*',
))
.addAnnotation(commonAnnotations.deploymentsForRunway('${type}'))
.addPanels(
  layout.grid(
    [
      basic.timeseries(
        title='Runway Service Request Count',
        description='Number of requests reaching the service.',
        yAxisLabel='Requests per Second',
        query=|||
          sum by (response_code_class, region, location) (
            rate(
              stackdriver_cloud_run_revision_run_googleapis_com_request_count{%(selector)s}[$__interval]
            )
          )
        ||| % formatConfig,
        legendFormat='{{response_code_class}} {{region}} {{location}}',
        intervalFactor=2,
      ),
      basic.latencyTimeseries(
        title='Runway Service Request Latency',
        description='Distribution of request times reaching the service, in milliseconds.',
        yAxisLabel='Duration',
        query=|||
          histogram_quantile(
            0.99,
            sum by (revision_name, region, location, le) (
              rate(stackdriver_cloud_run_revision_run_googleapis_com_request_latencies_bucket{%(selector)s}[$__interval])
            )
          )
        ||| % formatConfig,
        format='ms',
        legendFormat='p99 {{revision_name}} {{region}} {{location}}',
        intervalFactor=2,
      ),
      basic.timeseries(
        title='Runway Service Container Instance Count',
        description='Number of container instances that exist for the service.',
        yAxisLabel='Container Instances per Second',
        query=|||
          sum by (revision_name, region, location) (
            max_over_time(
              stackdriver_cloud_run_revision_run_googleapis_com_container_instance_count{%(selector)s}[${__interval}]
            )
          )
        ||| % formatConfig,
        legendFormat='{{revision_name}} {{region}} {{location}}',
        intervalFactor=2,
      ),
      basic.timeseries(
        title='Runway Service Billable Container Instance Time',
        description='Billable time aggregated from all container instances.',
        yAxisLabel='Requests per Second',
        query=|||
          sum by (service_name) (
            rate(
              stackdriver_cloud_run_revision_run_googleapis_com_container_billable_instance_time{%(selector)s}[${__interval}]
            )
          )
        ||| % formatConfig,
        legendFormat='{{service_name}}',
        intervalFactor=2,
      ),
      basic.percentageTimeseries(
        title='Runway Service CPU Utilization',
        description='Container CPU utilization distribution across all container instances.',
        query=|||
          histogram_quantile(
            0.99,
            sum by (revision_name, region, location, le) (
              max_over_time(stackdriver_cloud_run_revision_run_googleapis_com_container_cpu_utilizations_bucket{%(selector)s}[$__interval])
            )
          )
        ||| % formatConfig,
        legendFormat='p99 {{revision_name}} {{region}} {{location}}',
        interval='2m',
        intervalFactor=3,
        min=0,
        max=1,
        decimals=2,
      ),
      basic.percentageTimeseries(
        title='Runway Service Memory Utilization',
        description='Container memory utilization distribution across all container instances.',
        query=|||
          histogram_quantile(
            0.99,
            sum by (revision_name, region, location, le) (
              max_over_time(stackdriver_cloud_run_revision_run_googleapis_com_container_memory_utilizations_bucket{%(selector)s}[$__interval])
            )
          )
        ||| % formatConfig,
        legendFormat='p99 {{revision_name}} {{region}} {{location}}',
        interval='2m',
        intervalFactor=3,
        min=0,
        max=1,
        decimals=2,
      ),
      basic.networkTrafficGraph(
        title='Runway Service Sent Bytes',
        description='Outgoing socket and HTTP response traffic, in bytes.',
        sendQuery=|||
          sum by (revision_name, region, location, kind) (
            rate(
              stackdriver_cloud_run_revision_run_googleapis_com_container_network_sent_bytes_count{%(selector)s}[$__rate_interval]
            )
          )
        ||| % formatConfig,
        legendFormat='{{kind}} {{revision_name}} {{region}} {{location}}',
      ),
      basic.networkTrafficGraph(
        title='Runway Service Received Bytes',
        description='Incoming socket and HTTP response traffic, in bytes.',
        receiveQuery=|||
          sum by (revision_name, region, location, kind) (
            rate(
              stackdriver_cloud_run_revision_run_googleapis_com_container_network_received_bytes_count{%(selector)s}[$__rate_interval]
            )
          )
        ||| % formatConfig,
        legendFormat='{{kind}} {{revision_name}} {{region}} {{location}}',
      ),
      basic.percentageTimeseries(
        title='Runway Service Max Concurrent Requests',
        description='Distribution of the maximum number number of concurrent requests being served by each container instance over a minute.',
        query=|||
          histogram_quantile(
            0.99,
            sum by (revision_name, region, location, le) (
              max_over_time(stackdriver_cloud_run_revision_run_googleapis_com_container_max_request_concurrencies_bucket{%(selector)s}[$__interval])
            )
          ) / 100
        ||| % formatConfig,
        legendFormat='p99 {{revision_name}} {{region}} {{location}}',
        interval='2m',
        intervalFactor=3,
        min=0,
        max=1,
        decimals=2,
      ),
      basic.latencyTimeseries(
        title='Runway Service Container Startup Latency',
        description='Distribution of time spent starting a new container instance, in milliseconds.',
        query=|||
          sum by (revision_name, region, location) (
            rate(
              stackdriver_cloud_run_revision_run_googleapis_com_container_startup_latencies_sum{%(selector)s}[$__interval]
            )
          )
        ||| % formatConfig,
        legendFormat='{{revision_name}} {{region}} {{location}}',
        format='ms',
        intervalFactor=2,
      ),
      basic.timeseries(
        title='Runway Service Container Healthcheck Requests',
        description='Request rate of healthcheck attempts for the ingress container',
        query=|||
          sum by (revision_name, region, location, probe_type, is_healthy) (
            stackdriver_cloud_run_revision_run_googleapis_com_container_completed_probe_attempt_count{%(selector)s, container_name='ingress'}
          )
        ||| % formatConfig,
        legendFormat='{{revision_name}} {{region}} {{location}} {{probe_type}} healthy: {{is_healthy}}',
        intervalFactor=2,
      ),
      basic.latencyTimeseries(
        title='Runway Service Container Healthcheck Latency',
        description='Distribution of time spent probing a container instance, in milliseconds.',
        query=|||
          sum by (revision_name, region, location, probe_type, is_healthy) (
            rate(
              stackdriver_cloud_run_revision_run_googleapis_com_container_probe_attempt_latencies_sum{%(selector)s, container_name='ingress'}[$__interval]
            )
          )
        ||| % formatConfig,
        legendFormat='{{revision_name}} {{region}} {{location}} {{probe_type}} healthy: {{is_healthy}}',
        format='ms',
        intervalFactor=2,
      ),
    ]
  )
)
