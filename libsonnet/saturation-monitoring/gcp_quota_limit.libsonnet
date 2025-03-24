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
    runbook: 'docs/uncategorized/alerts/gcp_quota_limit.md',
    description: |||
      GCP Quota utilization / limit ratio

      Saturation on a quota may cause problems with creating infrastructure resources on GCP.

      To fix, we can request a quota increase for the specific resource to the GCP support team.
    |||,
    grafana_dashboard_uid: 'gcp_quota_limit',
    resourceLabels: ['project', 'metric', 'quotaregion', 'region'],
    useResourceLabelsAsMaxAggregationLabels: true,
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
    capacityPlanning: {
      saturation_dimensions: [
        { selector: selectors.serializeHash({ region: 'us-central1' }) },
        { selector: selectors.serializeHash({ region: 'us-east1' }) },
        { selector: selectors.serializeHash({ region: 'us-east4' }) },
      ],
    },
  }),

  // TODO: Remove the code-gecko exclusion once we have the capability to drill down
  // into dimensions in Tamland https://gitlab.com/gitlab-com/gl-infra/tamland/-/issues/74
  gcp_quota_limit_vertex_ai: resourceSaturationPoint(self.gcp_quota_limit {
    severity: 's4',
    appliesTo: ['ai-gateway'],
    grafana_dashboard_uid: 'sat_gcp_quota_limit_vertex_ai',
    // TODO: remove this location label, it is used in Thanos environments where
    // the `region` label is overridden as an external label advertised by prometheus
    // https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/3398
    resourceLabels: ['base_model', 'region', 'location'],
    burnRatePeriod: '5m',
    description: |||
      GCP Quota utilization / limit ratio for all vertex AI models except code-gecko.

      Saturation on the quota may cause problems with the requests.

      To fix, we can request a quota increase for the specific resource to the GCP support team.
    |||,
    query: |||
      (
        sum without (method) (stackdriver_aiplatform_googleapis_com_location_aiplatform_googleapis_com_quota_online_prediction_requests_per_base_model_usage{%(selector)s,base_model!="code-gecko"})
      /
        stackdriver_aiplatform_googleapis_com_location_aiplatform_googleapis_com_quota_online_prediction_requests_per_base_model_limit{%(selector)s,base_model!="code-gecko"}
      ) > 0
    |||,
    capacityPlanning: {
      saturation_dimensions: [
        { selector: selectors.serializeHash({ region: 'us-east4' }) },
      ],
    },
  }),

  gcp_quota_limit_vertex_ai_code_gecko: resourceSaturationPoint(self.gcp_quota_limit_vertex_ai {
    grafana_dashboard_uid: 'sat_vertex_ai_code_gecko_quota',
    description: |||
      GCP Quota utilization / limit ratio for Vertex AI for code-gecko model (used by code completion part of Code Suggestions)

      Saturation on the quota may cause problems with code completion requests.

      To fix, we can request a quota increase for the specific resource to the GCP support team.
    |||,
    query: |||
      (
        sum without (method) (stackdriver_aiplatform_googleapis_com_location_aiplatform_googleapis_com_quota_online_prediction_requests_per_base_model_usage{%(selector)s,base_model="code-gecko"})
      /
        stackdriver_aiplatform_googleapis_com_location_aiplatform_googleapis_com_quota_online_prediction_requests_per_base_model_limit{%(selector)s,base_model="code-gecko"}
      ) > 0
    |||,
    capacityPlanning: {
      saturation_dimensions: [
        { selector: selectors.serializeHash({ region: 'asia-northeast1' }) },
        { selector: selectors.serializeHash({ region: 'asia-northeast3' }) },
        { selector: selectors.serializeHash({ region: 'europe-west2' }) },
        { selector: selectors.serializeHash({ region: 'europe-west3' }) },
        { selector: selectors.serializeHash({ region: 'europe-west9' }) },
        { selector: selectors.serializeHash({ region: 'us-central1' }) },
      ],
    },
  }),

  gcp_quota_limit_vertex_ai_tokens: resourceSaturationPoint(self.gcp_quota_limit {
    severity: 's4',
    appliesTo: ['ai-gateway'],
    grafana_dashboard_uid: 'sat_gcp_quota_vertex_ai_tokens',
    // TODO: remove this location label, it is used in Thanos environments where
    // the `region` label is overridden as an external label advertised by prometheus
    // https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/3398
    resourceLabels: ['base_model', 'region', 'location'],
    burnRatePeriod: '5m',
    description: |||
      GCP Quota utilization / limit ratio for tokens per minute per model and region. This quota is currently only enforced for the
      `mistralai-codestral-2501` model used by Code Suggestions

      Saturation on the quota may cause problems with the requests.

      To fix, we can request a quota increase for the specific resource to the GCP support team.
    |||,
    query: |||
      (
        sum without (method) (stackdriver_aiplatform_googleapis_com_location_aiplatform_googleapis_com_quota_online_prediction_tokens_per_minute_per_base_model_usage{%(selector)s})
      /
        stackdriver_aiplatform_googleapis_com_location_aiplatform_googleapis_com_quota_online_prediction_tokens_per_minute_per_base_model_limit{%(selector)s}
      ) > 0
    |||,
  }),
}
