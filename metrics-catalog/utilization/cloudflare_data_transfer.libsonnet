local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local utilizationMetric = metricsCatalog.utilizationMetric;

{
  cloudflare_data_transfer: utilizationMetric({
    title: 'Cloudflare Network Total Data Transfer',
    unit: 'bytes',
    appliesTo: ['waf'],
    description: |||
      Tracks total data transfer across the cloudflare network
    |||,
    grafana_dashboard_uid: 'util_cloudflare_data_transfer',
    resourceLabels: ['zone'],
    query: |||
      sum by (%(aggregationLabels)s) (
        rate(cloudflare_zones_http_country_bytes_total{%(selector)s}[1h])
      )
    |||
  }),
}
