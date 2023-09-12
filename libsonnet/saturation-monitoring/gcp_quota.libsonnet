local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local resourceSaturationPoint = metricsCatalog.resourceSaturationPoint;
local selectors = import 'promql/selectors.libsonnet';

{
  gcp_quota: resourceSaturationPoint({
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
    grafana_dashboard_uid: 'gcp_quota',
    resourceLabels: ['project', 'metric', 'quotaregion'],
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
  gcp_quota_s4: resourceSaturationPoint(self.gcp_quota {
    severity: 's4',
    appliesTo: ['code_suggestions', 'ai-gateway'],
    grafana_dashboard_uid: 'gcp_quota_s4',
  }),

  gcp_quota_vertex_ai: resourceSaturationPoint(self.gcp_quota_s4 {
    grafana_dashboard_uid: 'sat_gcp_quota_vertex_ai',
    resourceLabels: ['base_model'],
    burnRatePeriod: '5m',
    query: |||
      (
        stackdriver_aiplatform_googleapis_com_location_aiplatform_googleapis_com_quota_online_prediction_requests_per_base_model_usage{%(selector)s}
      / ignoring (method)
        stackdriver_aiplatform_googleapis_com_location_aiplatform_googleapis_com_quota_online_prediction_requests_per_base_model_limit{%(selector)s}
      ) > 0
    |||,
  }),

  gcp_quota_vertex_ai_text_bison: resourceSaturationPoint(self.gcp_quota_s4 {
    grafana_dashboard_uid: 'sat_gcp_quota_vertex_ai_text_bison',
    query: |||
      (
        stackdriver_aiplatform_googleapis_com_location_aiplatform_googleapis_com_quota_online_prediction_requests_per_base_model_usage{base_model="text-bison",%(selector)s}
      / ignoring (method)
        stackdriver_aiplatform_googleapis_com_location_aiplatform_googleapis_com_quota_online_prediction_requests_per_base_model_limit{base_model="text-bison",%(selector)s}
      ) > 0
    |||,
  }),

  gcp_quota_vertex_ai_code_gecko: resourceSaturationPoint(self.gcp_quota_s4 {
    grafana_dashboard_uid: 'sat_gcp_quota_vertex_ai_code_gecko',
    query: |||
      (
        stackdriver_aiplatform_googleapis_com_location_aiplatform_googleapis_com_quota_online_prediction_requests_per_base_model_usage{base_model="code-gecko",%(selector)s}
      / ignoring (method)
        stackdriver_aiplatform_googleapis_com_location_aiplatform_googleapis_com_quota_online_prediction_requests_per_base_model_limit{base_model="code-gecko",%(selector)s}
      ) > 0
    |||,
  }),
}
