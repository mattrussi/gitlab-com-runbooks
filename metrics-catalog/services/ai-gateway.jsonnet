local runwayArchetype = import 'service-archetypes/runway-archetype.libsonnet';
local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local rateMetric = metricsCatalog.rateMetric;
local histogramApdex = metricsCatalog.histogramApdex;
local toolingLinks = import 'toolinglinks/toolinglinks.libsonnet';

local baseSelector = { type: 'ai-gateway' };

metricsCatalog.serviceDefinition(
  // Default Runway SLIs
  runwayArchetype(
    type='ai-gateway',
    team='code_creation',
    featureCategory='code_suggestions',
    apdexSatisfiedThreshold=2048,
    customToolingLinks=[
      toolingLinks.kibana(
        title='MLOps',
        index='mlops',
        includeMatchersForPrometheusSelector=false,
        matches={ 'json.jsonPayload.project_id': 'gitlab-runway-production' }
      ),
    ]
  )
  // Custom AI Gateway SLIs
  {
    serviceLevelIndicators+: {
      server: {
        severity: 's4',
        userImpacting: true,
        serviceAggregation: false,
        team: 'code_creation',
        featureCategory: 'code_suggestions',
        description: |||
          FastAPI server for AI Gateway.
        |||,

        apdex: histogramApdex(
          histogram='http_request_duration_seconds_bucket',
          selector=baseSelector { status: { noneOf: ['4xx', '5xx'] } },
          satisfiedThreshold='2.5',
          toleratedThreshold='10.0'
        ),

        requestRate: rateMetric(
          counter='http_request_duration_seconds_count',
          selector=baseSelector,
          useRecordingRuleRegistry=false,
        ),

        errorRate: rateMetric(
          counter='http_request_duration_seconds_count',
          selector=baseSelector { status: '5xx' },
          useRecordingRuleRegistry=false,
        ),

        significantLabels: ['status', 'handler', 'method'],

        toolingLinks: [
          toolingLinks.kibana(
            title='FastAPI Server',
            index='mlops',
            includeMatchersForPrometheusSelector=false,
            matches={ 'json.jsonPayload.logger': 'api.access' }
          ),
        ],
      },
      inference: {
        local inferenceSelector = baseSelector { model_engine: { ne: 'codegen' } },
        severity: 's4',
        userImpacting: true,
        serviceAggregation: false,
        team: 'code_creation',
        featureCategory: 'code_suggestions',
        trafficCessationAlertConfig: false,
        description: |||
          Vertex AI API model inference requests for AI Gateway.
        |||,

        apdex: histogramApdex(
          histogram='code_suggestions_inference_request_duration_seconds_bucket',
          selector=baseSelector,
          satisfiedThreshold='5.0',
          toleratedThreshold='10.0'
        ),

        requestRate: rateMetric(
          counter='code_suggestions_inference_requests_total',
          selector=baseSelector,
        ),

        significantLabels: ['model_engine', 'model_name'],

        toolingLinks: [
          toolingLinks.kibana(
            title='Model Inference',
            index='mlops',
            includeMatchersForPrometheusSelector=false,
            matches={ 'json.jsonPayload.model_engine': 'vertex-ai' }
          ),
        ],
      },
      waf: {
        local hostSelector = { zone: 'gitlab.com', host: { re: 'codesuggestions.gitlab.com.*' } },
        severity: 's4',
        userImpacting: true,
        serviceAggregation: false,
        team: 'code_creation',
        featureCategory: 'code_suggestions',
        description: |||
          Cloudflare WAF and rate limit rules for codesuggestions.gitlab.com host.
        |||,
        staticLabels: {
          env: 'ops',
        },

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
    },
  }
)
