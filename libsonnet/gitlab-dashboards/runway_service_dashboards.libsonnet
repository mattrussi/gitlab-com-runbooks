local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local basic = import 'grafana/basic.libsonnet';
local layout = import 'grafana/layout.libsonnet';
local selectors = import 'promql/selectors.libsonnet';
local metricsCatalog = import 'servicemetrics/metrics-catalog.libsonnet';
local row = grafana.row;

// Default service overview dashboard panels for Runway services
local panelsForService(type) =
  local formatConfig = {
    selector: selectors.serializeHash({ env: '$environment', environment: '$environment', type: type }),
  };

  [
    basic.networkTrafficGraph(
      title='Runway Network I/O',
      description='Incoming and outgoing socket and HTTP response traffic.',
      sendQuery=|||
        sum by (revision_name, kind) (
          rate(
            stackdriver_cloud_run_revision_run_googleapis_com_container_network_sent_bytes_count{%(selector)s}[$__rate_interval]
          )
        )
      ||| % formatConfig,
      receiveQuery=|||
        sum by (revision_name, kind) (
          rate(
            stackdriver_cloud_run_revision_run_googleapis_com_container_network_received_bytes_count{%(selector)s}[$__rate_interval]
          )
        )
      ||| % formatConfig,
      legendFormat='{{revision}} {{kind}}',
    ),
    basic.latencyTimeseries(
      title='Runway Container Startup Latency',
      description='Time spent starting a new container instance.',
      query=|||
        sum by (revision_name) (
          rate(
            stackdriver_cloud_run_revision_run_googleapis_com_container_startup_latencies_sum{%(selector)s}[$__interval]
          )
        )
      ||| % formatConfig,
      legendFormat='{{revision_name}}',
      format='ms',
      intervalFactor=2,
    ),
    basic.latencyTimeseries(
      title='Runway Container Probe Latency',
      description='Time spent running a probe before success or failure.',
      query=|||
        sum by (revision_name, probe_type) (
          rate(
            stackdriver_cloud_run_revision_run_googleapis_com_container_probe_latencies_sum{%(selector)s}[$__interval]
          )
        )
      ||| % formatConfig,
      legendFormat='{{revision_name}} {{probe_type}}',
      format='ms',
      intervalFactor=2,
    ),
  ];

local serviceOverview(type, startRow=1) =
  layout.grid(
    panelsForService(type),
  );

{
  serviceOverview:: serviceOverview,
}
