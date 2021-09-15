local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local resourceSaturationPoint = metricsCatalog.resourceSaturationPoint;

{
  gcp_quota: resourceSaturationPoint({
    title: 'GCP Quota utilization per environment',
    severity: 's4',
    horizontallyScalable: false,
    appliesTo: { allExcept: [] },
    burnRatePeriod: '15m',
    description: |||
      GCP Quota utilization / limit ratio

      Saturation on a quota may cause problems with creating infrastructure resources on GCP.

      To fix, we can request a quota increase for the specific resource to the GCP support team.
    |||,
    grafana_dashboard_uid: 'gcp_quota_limits',
    resourceLabels: ['metric'],
    query: |||
      (
        gcp_quota_usage{%(selector)s}
      )
      /
      gcp_quota_limit{%(selector)s}
    |||,
    slos: {
      soft: 0.85,
      hard: 0.95,
      alertTriggerDuration: '10m',
    },
  }),
}
