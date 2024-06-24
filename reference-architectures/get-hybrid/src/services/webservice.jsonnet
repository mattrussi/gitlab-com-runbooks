local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local rateMetric = metricsCatalog.rateMetric;
local kubeLabelSelectors = metricsCatalog.kubeLabelSelectors;
local successCounterApdex = metricsCatalog.successCounterApdex;

metricsCatalog.serviceDefinition({
  type: 'webservice',
  tier: 'sv',

  tags: ['golang', 'rails', 'puma'],

  monitoringThresholds: {
    apdexScore: 0.998,
    errorRatio: 0.9999,
  },

  otherThresholds: {},
  serviceDependencies: {},
  // recordingRuleMetrics: [
  //   'http_requests_total',
  // ],
  provisioning: {
    vms: false,
    kubernetes: true,
  },
  regional: false,
  kubeConfig: {
    local kubeSelector = { app: 'webservice' },
    labelSelectors: kubeLabelSelectors(
      podSelector=kubeSelector,
      hpaSelector=kubeSelector,
      nodeSelector={ eks_amazonaws_com_nodegroup: 'gitlab_webservice_pool' },
      ingressSelector=kubeSelector,
      deploymentSelector=kubeSelector
    ),
  },
  kubeResources: {
    'gitlab-webservice-default': {
      kind: 'Deployment',
      containers: [
        'gitlab-workhorse',
        'webservice',
      ],
    },
  },

  // A 98% confidence interval will be used for all SLIs on this service
  useConfidenceLevelForSLIAlerts: '98%',

  serviceLevelIndicators:
    {
      puma: {
        userImpacting: true,
        description: |||
          Aggregation of most web requests that pass through the puma to the GitLab rails monolith.
          Healthchecks are excluded.
        |||,

        local baseSelector = { job: 'gitlab-rails' },

        apdex: successCounterApdex(
          successRateMetric='gitlab_sli_rails_request_apdex_success_total',
          operationRateMetric='gitlab_sli_rails_request_apdex_total',
          selector=baseSelector,
        ),

        requestRate: rateMetric(
          counter='http_requests_total',
          selector=baseSelector,
        ),

        errorRate: rateMetric(
          counter='http_requests_total',
          selector=baseSelector { status: { re: '5..' } }
        ),

        significantLabels: [],

        toolingLinks: [],
      },

      local workhorseSelector = {
        route: {
          ne: [
            '^/-/health$',
            '^/-/(readiness|liveness)$',
          ],
        },
      },

      local nonAPIWorkhorseSelector = workhorseSelector { route+: { nre+: ['^\\\\^/api/.*'] } },
      local apiWorkhorseSelector = workhorseSelector { route+: { re+: ['^\\\\^/api/.*'] } },

      workhorse: {
        userImpacting: true,
        featureCategory: 'not_owned',
        description: |||
          Aggregation of most rails requests that pass through workhorse, monitored via the HTTP interface.
          Excludes API requests health, readiness and liveness requests. Some known slow requests,
          such as HTTP uploads, are excluded from the apdex score.
        |||,

        apdex: histogramApdex(
          histogram='gitlab_workhorse_http_request_duration_seconds_bucket',
          selector=nonAPIWorkhorseSelector {
            route+: {
              ne+: [
                '^/([^/]+/){1,}[^/]+/uploads\\\\z',  // ^/([^/]+/){1,}[^/]+/uploads\z
                '^/.+\\\\.git/git-receive-pack\\\\z',  // ^/.+\.git/git-receive-pack\z
                '^/.+\\\\.git/git-upload-pack\\\\z',  // ^/.+\.git/git-upload-pack\z
                '^/.+\\\\.git/info/refs\\\\z',  // ^/.+\.git/info/refs\z
                '^/.+\\\\.git/gitlab-lfs/objects/([0-9a-f]{64})/([0-9]+)\\\\z',  // /.+\.git/gitlab-lfs/objects/([0-9a-f]{64})/([0-9]+)\z
                '^/-/cable\\\\z',  // ^/-/cable\z
              ],
            },
          },
          satisfiedThreshold=1,
          toleratedThreshold=10
        ),

        requestRate: rateMetric(
          counter='gitlab_workhorse_http_requests_total',
          selector=nonAPIWorkhorseSelector,
        ),

        errorRate: rateMetric(
          counter='gitlab_workhorse_http_requests_total',
          selector=nonAPIWorkhorseSelector {
            code: { re: '^5.*' },
          },
        ),

        significantLabels: ['route'],

        toolingLinks: [],
      },

      workhorse_api: {
        userImpacting: true,
        featureCategory: 'not_owned',
        description: |||
          Aggregation of most API requests that pass through workhorse, monitored via the HTTP interface.

          The workhorse API apdex has a longer apdex latency than the web to allow for slow API requests.
        |||,

        apdex: histogramApdex(
          histogram='gitlab_workhorse_http_request_duration_seconds_bucket',
          selector=apiWorkhorseSelector,
          satisfiedThreshold=10
        ),

        requestRate: rateMetric(
          counter='gitlab_workhorse_http_requests_total',
          selector=apiWorkhorseSelector,
        ),

        errorRate: rateMetric(
          counter='gitlab_workhorse_http_requests_total',
          selector=apiWorkhorseSelector {
            code: { re: '^5.*' },
          },
        ),

        significantLabels: ['route'],

        toolingLinks: [],
      },

      graphql_query: {
        userImpacting: true,
        serviceAggregation: false,  // The requests are already counted in the `puma` SLI.
        description: |||
          A GraphQL query is executed in the context of a request. An error does not
          always result in a 5xx error. But could contain errors in the response.
          Mutliple queries could be batched inside a single request.

          This SLI counts all operations, a succeeded operation does not contain errors in
          it's response or return a 500 error.

          The number of GraphQL queries meeting their duration target based on the urgency
          of the endpoint. By default, a query should take no more than 1s. We're working
          on making the urgency customizable in [this epic](https://gitlab.com/groups/gitlab-org/-/epics/5841).

          We're only taking known operations into account. Known operations are queries
          defined in our codebase and originating from our frontend.
        |||,

        local knownOperationsSelector = { job: 'gitlab-rails', endpoint_id: { ne: 'graphql:unknown' } },

        requestRate: rateMetric(
          counter='gitlab_sli_graphql_query_total',
          selector=knownOperationsSelector,
        ),

        errorRate: rateMetric(
          counter='gitlab_sli_graphql_query_error_total',
          selector=knownOperationsSelector,
        ),

        apdex: successCounterApdex(
          successRateMetric='gitlab_sli_graphql_query_apdex_success_total',
          operationRateMetric='gitlab_sli_graphql_query_apdex_total',
          selector=knownOperationsSelector,
        ),

        significantLabels: ['endpoint_id'],

      },
    },

  extraRecordingRulesPerBurnRate: [],
})
