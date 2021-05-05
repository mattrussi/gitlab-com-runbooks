local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local resourceSaturationPoint = metricsCatalog.resourceSaturationPoint;
local kubeSaturationHelpers = import 'helpers/kube_saturation_helpers.libsonnet';

{
  node_schedstat_waiting: resourceSaturationPoint({
    title: 'Node Scheduler Waiting Time',
    appliesTo: { allExcept: ['nat', 'waf', 'console-node', 'deploy-node', 'security' /* ops-only security scanning service */] + kubeSaturationHelpers.kubeOnlyServices, default: 'sidekiq' },
    severity: 's4',
    horizontallyScalable: true,
    description: |||
      Measures the amount of scheduler waiting time that processes are waiting
      to be scheduled, according to [`CPU Scheduling Metrics`](https://www.robustperception.io/cpu-scheduling-metrics-from-the-node-exporter).

      A high value indicates that a node has more processes to be run than CPU time available
      to handle them, and may lead to degraded responsiveness and performance from the application.

      Additionally, it may indicate that the fleet is under-provisioned.
    |||,
    grafana_dashboard_uid: 'sat_node_schedstat_waiting',
    resourceLabels: ['fqdn', 'shard'],
    // Deliberately use a long burn rate period here, to
    // round-down any short spikes. We're looking for
    // long term issues
    burnRatePeriod: '1h',
    query: |||
      avg without (cpu) (rate(node_schedstat_waiting_seconds_total{%(selector)s}[%(rangeInterval)s]))
    |||,
    slos: {
      soft: 0.10,
      hard: 0.15,
      alertTriggerDuration: '90m',
    },
  }),
}
