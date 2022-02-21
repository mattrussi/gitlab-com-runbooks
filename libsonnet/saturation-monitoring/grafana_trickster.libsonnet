local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local resourceSaturationPoint = metricsCatalog.resourceSaturationPoint;

{
  grafana_trickster_cache_usage: resourceSaturationPoint({
    title: 'Grafana Trickster cache usage',
    severity: 's3',
    horizontallyScalable: false,
    appliesTo: ['monitoring'],
    burnRatePeriod: '5m',
    description: |||
      Trickster cache usage / limit ratio

      Saturation of the Trickster cache may performance issues when displaying dashboards in Grafana.

      To fix, we can tune the cached objects TTL or eviction method, or increase the cache size.
    |||,
    grafana_dashboard_uid: 'grafana_trickster_cache_usage',
    resourceLabels: ['pod'],
    query: |||
      (
        trickster_cache_usage_bytes{%(selector)s}
      /
        trickster_cache_max_usage_bytes{%(selector)s}
      ) > 0
    |||,
    slos: {
      soft: 0.85,
      hard: 0.95,
      alertTriggerDuration: '15m',
    },
  }),
}
