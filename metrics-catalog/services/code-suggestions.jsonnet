local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local rateMetric = metricsCatalog.rateMetric;
local histogramApdex = metricsCatalog.histogramApdex;
local toolingLinks = import 'toolinglinks/toolinglinks.libsonnet';

local baseSelector = { type: 'code_suggestions' };

// DEPRECATION WARNING: `code_suggestions` service will be removed in https://gitlab.com/gitlab-com/runbooks/-/issues/133
// Use `ai-gateway` service: https://gitlab.com/gitlab-com/runbooks/-/blob/master/metrics-catalog/services/ai-gateway.jsonnet

metricsCatalog.serviceDefinition({
  type: 'code_suggestions',
  tier: 'sv',
  monitoringThresholds: {
    apdexScore: 0.99,
    errorRatio: 0.999,
  },
  provisioning: {
    vms: false,
    kubernetes: true,
  },
  serviceDependencies: {
    api: true,
  },
  serviceIsStageless: true,
  tags: ['filestore', 'nv_gpu'],

  // This is evaluated in Thanos because the prometheus uses thanos-receive to
  // get its metrics available.
  // Our recording rules are currently not deployed to the external cluster that runs
  // code-suggestions.
  // We should get rid of this to be in line with other services when we can
  dangerouslyThanosEvaluated: true,

  local gkeDeploymentDetails = {
    project: 'unreview-poc-390200e5',
    region: 'us-central1-c',
    cluster: 'ai-assist',
  },

  serviceLevelIndicators: {
    model_gateway: {
      local modelGatewaySelector = baseSelector { container: 'model-gateway' },
      severity: 's4',  // NOTE: Do not page on-call SREs until production ready
      userImpacting: true,
      team: 'code_creation',
      featureCategory: 'code_suggestions',
      serviceAggregation: false,

      requestRate: rateMetric(
        counter='http_request_duration_seconds_count',
        selector=modelGatewaySelector,
        useRecordingRuleRegistry=false,
      ),

      errorRate: rateMetric(
        counter='http_request_duration_seconds_count',
        selector=modelGatewaySelector { status: '5xx' },
        useRecordingRuleRegistry=false,
      ),

      apdex: histogramApdex(
        histogram='http_request_duration_seconds_bucket',
        selector=modelGatewaySelector { status: { noneOf: ['4xx', '5xx'] } },
        satisfiedThreshold='2.5',
        toleratedThreshold='10.0'
      ),

      significantLabels: ['status', 'handler', 'method'],

      toolingLinks: [
        toolingLinks.gkeDeployment(
          'model-gateway',
          namespace='fauxpilot',
          containerName='model-gateway',
          project=gkeDeploymentDetails.project,
          region=gkeDeploymentDetails.region,
          cluster=gkeDeploymentDetails.cluster,
        ),
        toolingLinks.kibana(title='MLOps', index='mlops', includeMatchersForPrometheusSelector=false),
      ],
    },

    triton_server: {
      local tritonSelector = baseSelector { container: 'triton' },
      severity: 's4',  // NOTE: Do not page on-call SREs until production ready
      userImpacting: true,
      team: 'code_creation',
      featureCategory: 'code_suggestions',
      serviceAggregation: false,

      requestRate: rateMetric(
        counter='nv_inference_count',
        selector=tritonSelector,
        useRecordingRuleRegistry=false,
      ),

      errorRate: rateMetric(
        counter='nv_inference_request_failure',
        selector=tritonSelector,
        useRecordingRuleRegistry=false,
      ),

      significantLabels: ['model'],

      toolingLinks: [
        toolingLinks.gkeDeployment(
          'model-triton',
          namespace='fauxpilot',
          containerName='triton',
          project=gkeDeploymentDetails.project,
          region=gkeDeploymentDetails.region,
          cluster=gkeDeploymentDetails.cluster,
        ),
        toolingLinks.grafana(title='Triton Server Detail', dashboardUid='code_suggestions-triton'),
      ],
    },

    waf: {
      local hostSelector = { zone: 'gitlab.com', host: { re: 'codesuggestions.gitlab.com.*' } },
      severity: 's4',  // NOTE: Do not page on-call SREs until production ready
      userImpacting: true,
      team: 'code_creation',
      featureCategory: 'code_suggestions',
      serviceAggregation: false,
      monitoringThresholds+: {
        errorRatio: 0.999,
      },
      description: |||
        Cloudflare WAF and rate limit rules for codesuggestions.gitlab.com host.
      |||,

      requestRate: rateMetric(
        counter='cloudflare_zone_requests_status_country_host',
        selector=hostSelector,
        useRecordingRuleRegistry=false,
      ),

      errorRate: rateMetric(
        counter='cloudflare_zone_requests_status_country_host',
        selector=hostSelector {
          status: { re: '^5.*' },
        },
        useRecordingRuleRegistry=false,
      ),

      significantLabels: ['status'],

      toolingLinks: [
        toolingLinks.cloudflare(host='codesuggestions.gitlab.com'),
        toolingLinks.grafana(title='WAF Overview', dashboardUid='waf-main/waf-overview'),
      ],
    },

    ingress: {
      local ingressSelector = baseSelector { container: 'controller', path: { ne: '/' } },
      severity: 's4',  // NOTE: Do not page on-call SREs until production ready
      userImpacting: true,
      team: 'code_creation',
      featureCategory: 'code_suggestions',
      serviceAggregation: true,
      description: |||
        Ingress-NGINX Controller for Kubernetes to expose service to the internet. Fronted by Cloudflare WAF.
      |||,

      requestRate: rateMetric(
        counter='nginx_ingress_controller_requests',
        selector=ingressSelector,
        useRecordingRuleRegistry=false,
      ),

      errorRate: rateMetric(
        counter='nginx_ingress_controller_requests',
        selector=ingressSelector {
          status: { re: '^5.*' },
        },
        useRecordingRuleRegistry=false,
      ),

      apdex: histogramApdex(
        histogram='nginx_ingress_controller_request_duration_seconds_bucket',
        selector=ingressSelector { status: { noneOf: ['4.*', '5.*'] } },
        satisfiedThreshold='2.5',
        toleratedThreshold='10'
      ),

      significantLabels: ['path', 'status', 'method'],

      toolingLinks: [
        toolingLinks.gkeDeployment(
          'nginx-ingress-nginx-controller',
          namespace='nginx',
          containerName='controller',
          project=gkeDeploymentDetails.project,
          region=gkeDeploymentDetails.region,
          cluster=gkeDeploymentDetails.cluster,
        ),
        toolingLinks.cloudflare(host='codesuggestions.gitlab.com'),
        toolingLinks.grafana(title='WAF Overview', dashboardUid='waf-main/waf-overview'),
      ],
    },

    native_model_inference: {
      local inferenceSelector = baseSelector { container: 'model-gateway', model_engine: 'codegen' },
      severity: 's4',  // NOTE: Do not page on-call SREs until production ready
      userImpacting: true,
      serviceAggregation: false,
      team: 'code_creation',
      featureCategory: 'code_suggestions',
      trafficCessationAlertConfig: false,  // NOTE: traffic can be routed 100% to either native vs third party
      description: |||
        Inference requests performed by native models.
      |||,

      apdex: histogramApdex(
        histogram='code_suggestions_inference_request_duration_seconds_bucket',
        selector=inferenceSelector,
        satisfiedThreshold='5.0',
        toleratedThreshold='10.0'
      ),

      requestRate: rateMetric(
        counter='code_suggestions_inference_requests_total',
        selector=inferenceSelector,
      ),

      significantLabels: ['model_engine', 'model_name'],

      toolingLinks: [
        toolingLinks.kibana(title='Native Models', index='mlops', matches={ 'json.jsonPayload.model_engine': 'codegen' }),
      ],
    },

    third_party_model_inference: {
      local inferenceSelector = baseSelector { container: 'model-gateway', model_engine: { ne: 'codegen' } },
      severity: 's4',  // NOTE: Do not page on-call SREs until production ready
      userImpacting: true,
      serviceAggregation: false,
      team: 'code_creation',
      featureCategory: 'code_suggestions',
      trafficCessationAlertConfig: false,  // NOTE: traffic can be routed 100% to either native vs third party
      description: |||
        Inference requests performed by third party models.
      |||,

      apdex: histogramApdex(
        histogram='code_suggestions_inference_request_duration_seconds_bucket',
        selector=inferenceSelector,
        satisfiedThreshold='5.0',
        toleratedThreshold='10.0'
      ),

      requestRate: rateMetric(
        counter='code_suggestions_inference_requests_total',
        selector=inferenceSelector,
      ),

      significantLabels: ['model_engine', 'model_name'],

      toolingLinks: [
        toolingLinks.kibana(title='Third Party Models', index='mlops', matches={ 'json.jsonPayload.model_engine': 'vertex-ai' }),
      ],
    },
  },
})
