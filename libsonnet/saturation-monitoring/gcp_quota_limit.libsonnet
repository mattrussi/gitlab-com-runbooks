local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local resourceSaturationPoint = metricsCatalog.resourceSaturationPoint;
local selectors = import 'promql/selectors.libsonnet';

{
  gcp_quota_limit: resourceSaturationPoint({
    title: 'GCP Quota utilization per environment',
    severity: 's2',
    horizontallyScalable: false,
    appliesTo: ['monitoring'],
    burnRatePeriod: '5m',
    description: |||
      GCP Quota utilization / limit ratio

      Saturation on a quota may cause problems with creating infrastructure resources on GCP.

      To fix, we can request a quota increase for the specific resource to the GCP support team.
    |||,
    grafana_dashboard_uid: 'gcp_quota_limit',
    resourceLabels: ['metric', 'quotaregion'],
    query: |||
      (
        gcp_quota_usage{%(selector)s}
      /
        gcp_quota_limit{%(selector)s}
      ) > 0
    |||,
    slos: {
      soft: 0.85,
      hard: 0.90,
      alertTriggerDuration: '15m',
    },
  }),

  // Code suggestions is currently not yet production ready. Remove this once it
  // is https://gitlab.com/gitlab-com/gl-infra/readiness/-/merge_requests/161
  gcp_quota_limit_s4: resourceSaturationPoint(self.gcp_quota_limit {
    severity: 's4',
    appliesTo: ['code_suggestions'],
    grafana_dashboard_uid: 'gcp_quota_limit_s4',
  }),

  // Due to discrepancies in GCP console, temporarily hardcode quota limit for saturation monitoring
  // Remove saturation resource when https://gitlab.com/gitlab-com/gl-infra/reliability/-/issues/24052 is complete
  gcp_quota_limit_vertex_ai: resourceSaturationPoint(self.gcp_quota_limit_s4 {
    grafana_dashboard_uid: 'sat_gcp_quota_limit_vertex_ai',
    resourceLabels: ['model_engine', 'model_name'],
    queryFormatConfig: {
      // Must manually update quota limit here after any increase requests approved in
      // https://console.cloud.google.com/iam-admin/quotas/qirs?project=unreview-poc-390200e5
      quotaLimit: 1000,
      modelSelector: selectors.serializeHash({
        model_engine: 'vertex-ai',
        model_name: 'PalmModel.CODE_GECKO',
      }),
    },
    burnRatePeriod: '1m',
    query: |||
      (
        rate(code_suggestions_inference_requests_total{%(modelSelector)s, %(selector)s}[%(rangeInterval)s]) * 60
        /
        %(quotaLimit)i
      ) > 0
    |||,
  }),
}
