local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local resourceSaturationPoint = metricsCatalog.resourceSaturationPoint;
local selectors = import 'promql/selectors.libsonnet';

{
  ai_gateway_threads: resourceSaturationPoint({
    title: 'AI Gateway threads count per environment',
    severity: 's3',
    horizontallyScalable: false,
    appliesTo: ['ai-gateway'],
    burnRatePeriod: '10m',
    description: |||
      The maximum number of threads running on AI Gateway on an Cloud Run instance.

      According to the [Cloud Run documentation](https://cloud.google.com/run/docs/tips/python),
      running too many threads can have a negative impact.

      This metric gives us an insight about the threading of AI Gateway is
      correctly tuned in the nature of Cloud Run.
    |||,
    grafana_dashboard_uid: 'ai_gateway_threads',
    query: |||
      max_over_time(ai_gateway_threads_count{env="gprd"}[5m])
    |||,
  }),
}
