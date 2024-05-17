local runwayArchetype = import 'service-archetypes/runway-archetype.libsonnet';
local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local rateMetric = metricsCatalog.rateMetric;
local histogramApdex = metricsCatalog.histogramApdex;
local toolingLinks = import 'toolinglinks/toolinglinks.libsonnet';
local runwayHelper = import 'service-archetypes/helpers/runway.libsonnet';
local matching = import 'elasticlinkbuilder/matching.libsonnet';
local serviceLevelIndicatorDefinition = import 'servicemetrics/service_level_indicator_definition.libsonnet';

local baseSelector = { type: 'ai-gateway' };
local serverSelector = baseSelector {
  handler: {
    noneOf:
      [
        '/v2/code/completions',
        '/v2/completions',
        '/v2/code/generations',
        '/v1/chat/agent',
        '/v1/x-ray/libraries',
      ],
  },
};
local serverCodeCompletionsSelector = baseSelector {
  handler: { oneOf: ['/v2/code/completions', '/v2/completions'] },
};
local serverCodeGenerationsSelector = baseSelector { handler: '/v2/code/generations' };
local serverChatSelector = baseSelector { handler: '/v1/chat/agent' };
local serverXRaySelector = baseSelector { handler: '/v1/x-ray/libraries' };

metricsCatalog.serviceDefinition(
  // Default Runway SLIs
  runwayArchetype(
    type='ai-gateway',
    team='code_creation',
    apdexScore=0.98,
    errorRatio=0.98,  // Temporary reduce until https://gitlab.com/gitlab-com/gl-infra/production/-/issues/17366 is fixed.
    featureCategory='code_suggestions',
    // Runway is using stackdriver metrics, these metrics use many buckets in miliseconds
    // To pick an available bucket, we need to look at the source metrics
    // https://dashboards.gitlab.net/goto/GiFs0eTIR?orgId=1
    // Pick a value that is larger than the server SLIs this encapsulates
    apdexSatisfiedThreshold='32989.690295920576',
    severity='s2',
    regional=true,
    customToolingLinks=[
      toolingLinks.kibana(
        title='MLOps',
        index='mlops',
        includeMatchersForPrometheusSelector=false,
        matches={ 'json.jsonPayload.project_id': 'gitlab-runway-production' }
      ),
    ],
    trafficCessationAlertConfig={ regional_component: { region: { re: 'us-.*' } } },
  )
  // Custom AI Gateway SLIs
  {
    // Labels set by
    // https://pypi.org/project/prometheus-fastapi-instrumentator
    local runwayLabels = runwayHelper.labels(self),
    local commonServerLabels = [
      'status',
      'handler',
      'method',
    ] + runwayLabels,

    serviceLevelIndicators+: {
      server: {
        severity: 's4',
        trafficCessationAlertConfig: false,
        userImpacting: true,
        serviceAggregation: false,
        team: 'code_creation',
        featureCategory: 'code_suggestions',
        description: |||
          FastAPI server for AI Gateway.
        |||,

        apdex: histogramApdex(
          histogram='http_request_duration_seconds_bucket',
          selector=serverSelector { status: { noneOf: ['4xx', '5xx'] } },
          satisfiedThreshold=5,
          toleratedThreshold=10,
          metricsFormat='migrating'
        ),

        requestRate: rateMetric(
          counter='http_request_duration_seconds_count',
          selector=serverSelector,
          useRecordingRuleRegistry=false,
        ),

        errorRate: rateMetric(
          counter='http_request_duration_seconds_count',
          selector=serverSelector { status: '5xx' },
          useRecordingRuleRegistry=false,
        ),

        significantLabels: commonServerLabels,

        toolingLinks: [
          toolingLinks.kibana(
            title='FastAPI Server',
            index='mlops',
            includeMatchersForPrometheusSelector=false,
            matches={ 'json.jsonPayload.logger': 'api.access' }
          ),
        ],
      },
      server_code_completions: {
        severity: 's2',
        userImpacting: true,
        serviceAggregation: false,
        team: 'code_creation',
        featureCategory: 'code_suggestions',
        trafficCessationAlertConfig: false,
        description: |||
          FastAPI server for AI Gateway - code completions.
        |||,

        apdex: histogramApdex(
          histogram='http_request_duration_seconds_bucket',
          selector=serverCodeCompletionsSelector { status: { noneOf: ['4xx', '5xx'] } },
          satisfiedThreshold=1,
          toleratedThreshold=10,
          metricsFormat='migrating'
        ),

        requestRate: rateMetric(
          counter='http_request_duration_seconds_count',
          selector=serverCodeCompletionsSelector,
          useRecordingRuleRegistry=false,
        ),

        errorRate: rateMetric(
          counter='http_request_duration_seconds_count',
          selector=serverCodeCompletionsSelector { status: '5xx' },
          useRecordingRuleRegistry=false,
        ),

        significantLabels: commonServerLabels,

        toolingLinks: [
          toolingLinks.kibana(
            title='FastAPI Server - code completions',
            index='mlops',
            includeMatchersForPrometheusSelector=false,
            matches={ 'json.jsonPayload.logger': 'api.access', 'json.jsonPayload.path': '/v2/code/completions' }
          ),
        ],
      },
      server_code_generations: {
        severity: 's2',
        userImpacting: true,
        serviceAggregation: false,
        team: 'code_creation',
        featureCategory: 'code_suggestions',
        trafficCessationAlertConfig: false,
        description: |||
          FastAPI server for AI Gateway - code generations.
        |||,

        apdex: histogramApdex(
          histogram='http_request_duration_seconds_bucket',
          selector=serverCodeGenerationsSelector { status: { noneOf: ['4xx', '5xx'] } },
          satisfiedThreshold=30,
          metricsFormat='migrating'
        ),

        requestRate: rateMetric(
          counter='http_request_duration_seconds_count',
          selector=serverCodeGenerationsSelector,
          useRecordingRuleRegistry=false,
        ),

        errorRate: rateMetric(
          counter='http_request_duration_seconds_count',
          selector=serverCodeGenerationsSelector { status: '5xx' },
          useRecordingRuleRegistry=false,
        ),

        significantLabels: commonServerLabels,

        toolingLinks: [
          toolingLinks.kibana(
            title='FastAPI Server - code generations',
            index='mlops',
            includeMatchersForPrometheusSelector=false,
            matches={ 'json.jsonPayload.logger': 'api.access', 'json.jsonPayload.path': '/v2/code/generations' }
          ),
        ],
      },
      server_chat: {
        severity: 's4',
        userImpacting: true,
        serviceAggregation: false,
        team: 'ai_framework',
        featureCategory: 'duo_chat',
        trafficCessationAlertConfig: false,
        description: |||
          FastAPI server for AI Gateway - chat.
        |||,

        apdex: histogramApdex(
          histogram='http_request_duration_seconds_bucket',
          selector=serverChatSelector { status: { noneOf: ['4xx', '5xx'] } },
          satisfiedThreshold=30,
          toleratedThreshold=60,
          metricsFormat='migrating'
        ),

        requestRate: rateMetric(
          counter='http_request_duration_seconds_count',
          selector=serverChatSelector,
          useRecordingRuleRegistry=false,
        ),

        errorRate: rateMetric(
          counter='http_request_duration_seconds_count',
          selector=serverChatSelector { status: '5xx' },
          useRecordingRuleRegistry=false,
        ),

        significantLabels: commonServerLabels,

        toolingLinks: [
          toolingLinks.kibana(
            title='FastAPI Server - chat',
            index='mlops',
            includeMatchersForPrometheusSelector=false,
            matches={ 'json.jsonPayload.logger': 'api.access', 'json.jsonPayload.path': '/v1/chat/agent' }
          ),
        ],
      },
      server_x_ray: {
        severity: 's4',
        userImpacting: true,
        serviceAggregation: false,
        team: 'code_creation',
        featureCategory: 'code_suggestions',
        trafficCessationAlertConfig: false,
        description: |||
          FastAPI server for AI Gateway - X-Ray.
        |||,

        apdex: histogramApdex(
          histogram='http_request_duration_seconds_bucket',
          selector=serverXRaySelector { status: { noneOf: ['4xx', '5xx'] } },
          satisfiedThreshold=30,
          toleratedThreshold=60,
          metricsFormat='migrating'
        ),

        requestRate: rateMetric(
          counter='http_request_duration_seconds_count',
          selector=serverXRaySelector,
          useRecordingRuleRegistry=false,
        ),

        errorRate: rateMetric(
          counter='http_request_duration_seconds_count',
          selector=serverXRaySelector { status: '5xx' },
          useRecordingRuleRegistry=false,
        ),

        significantLabels: commonServerLabels,

        toolingLinks: [
          toolingLinks.kibana(
            title='FastAPI Server - X-Ray',
            index='mlops',
            includeMatchersForPrometheusSelector=false,
            matches={ 'json.jsonPayload.logger': 'api.access', 'json.jsonPayload.path': '/v1/x-ray/libraries' }
          ),
        ],
      },
      inference: {
        severity: 's2',
        userImpacting: true,
        serviceAggregation: false,
        team: 'code_creation',
        featureCategory: serviceLevelIndicatorDefinition.featureCategoryFromSourceMetrics,
        trafficCessationAlertConfig: false,
        description: |||
          Inferences to the different model engines used by the AI-gateway.

          Apdex applies to non-streaming inferences, they are considered fast enough
          when the request took less than 30s. Errors don't count toward apdex

          A failure means an inference threw an error, for example when the model is
          not available.
        |||,

        apdex: histogramApdex(
          histogram='inference_request_duration_seconds_bucket',
          selector=baseSelector { 'error': 'no', streaming: 'no' },
          satisfiedThreshold=30,
          toleratedThreshold=60,
        ),

        errorRate: rateMetric(counter='model_inferences_total', selector=baseSelector { 'error': 'yes' }),

        requestRate: rateMetric(
          counter='model_inferences_total',
          selector=baseSelector,
        ),

        significantLabels: ['model_engine', 'model_name', 'feature_category'] + runwayLabels,

        toolingLinks: [
          toolingLinks.kibana(
            title='Model Inference',
            index='mlops',
            includeMatchersForPrometheusSelector=false,
            filters=[matching.existsFilter('json.jsonPayload.model_engine')],
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
          toolingLinks.grafana(title='CloudFlare Overview', dashboardUid='cloudflare-main/cloudflare-overview'),
        ],
      },
    },
  }
)
