local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local rateMetric = metricsCatalog.rateMetric;
local kubeLabelSelectors = metricsCatalog.kubeLabelSelectors;
local successCounterApdex = metricsCatalog.successCounterApdex;
local workhorseRoutes = import 'gitlab-utils/workhorse-routes.libsonnet';
local railsQueueingSli = import 'service-archetypes/helpers/rails_queueing_sli.libsonnet';

metricsCatalog.serviceDefinition({
  type: 'webservice',
  tier: 'sv',

  tags: ['golang', 'rails', 'puma', 'kube_container_rss'],

  monitoringThresholds: {
    apdexScore: 0.998,
    errorRatio: 0.999,
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
          // Ignoring GraphQL here because that is also monitored in the `graphql_query` SLI below
          // in that other SLI, we are ignoring queries that don't come from our
          // own application, because we have no control over those queries.
          selector=baseSelector { endpoint_id: { ne: 'GraphqlController#execute' } },
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
        route_id: {
          ne: [
            'health',
            'liveness',
          ],
        },
        // Ignoring GraphQL here because that is also monitored in the `graphql_query` SLI below
        // in that other SLI, we are ignoring queries that don't come from our
        // own application, because we have no control over those queries.
        endpoint_id: {
          ne: 'GraphqlController#execute',
        },
      },

      // Routes associated with api traffic
      local apiRoutes = ['^api.*'],

      // Routes associated with git traffic
      local gitRouteRegexps = [
        '^git_receive_pack$',
        '^git_upload_pack$',
        '^git_lfs_objects$',
        '^git_info_refs$',
      ],

      local nonAPIWorkhorseSelector = workhorseSelector { route_id+: { nre+: apiRoutes, noneOf: gitRouteRegexps } },
      local apiWorkhorseSelector = workhorseSelector { route_id+: { re+: apiRoutes } },
      local gitWorkhorseSelector = { route_id: { oneOf: gitRouteRegexps } },
      local workhorseApdexSelector = { code: { nre: '5..' } },

      workhorse: {
        userImpacting: true,
        featureCategory: 'not_owned',
        serviceAggregation: false,
        description: |||
          Aggregation of most rails requests that pass through workhorse, monitored via the HTTP interface.
          Excludes API requests, git requests, health, readiness and liveness requests. Some known slow requests,
          such as HTTP uploads, are excluded from the apdex score.
        |||,

        apdex: histogramApdex(
          histogram='gitlab_workhorse_http_request_duration_seconds_bucket',
          selector=nonAPIWorkhorseSelector + workhorseApdexSelector {
            // In addition to excluding all git and API traffic, exclude
            // these routes from apdex as they have variable durations
            route_id+: {
              ne+: [
                'project_uploads',
                'action_cable',
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

        significantLabels: ['route_id', 'code'],

        toolingLinks: [],
      },

      workhorse_api: {
        userImpacting: true,
        featureCategory: 'not_owned',
        serviceAggregation: false,
        description: |||
          Aggregation of most API requests that pass through workhorse, monitored via the HTTP interface.

          The workhorse API apdex has a longer apdex latency than the web to allow for slow API requests.
        |||,

        apdex: histogramApdex(
          histogram='gitlab_workhorse_http_request_duration_seconds_bucket',
          selector=apiWorkhorseSelector + workhorseApdexSelector,
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

        significantLabels: ['route_id', 'code'],

        toolingLinks: [],
      },

      workhorse_git: {
        userImpacting: true,
        serviceAggregation: false,
        featureCategory: 'not_owned',
        description: |||
          Aggregation of git+https requests that pass through workhorse,
          monitored via the HTTP interface.

          For apdex score, we avoid potentially long running requests, so only use the info-refs
          endpoint for monitoring git+https performance.
        |||,

        apdex: histogramApdex(
          histogram='gitlab_workhorse_http_request_duration_seconds_bucket',
          selector=workhorseApdexSelector {
            // We only use the info-refs endpoint, not long-duration clone endpoints
            route_id: ['git_info_refs'],
          },
          satisfiedThreshold=10
        ),

        requestRate: rateMetric(
          counter='gitlab_workhorse_http_requests_total',
          selector=gitWorkhorseSelector,
        ),

        errorRate: rateMetric(
          counter='gitlab_workhorse_http_requests_total',
          selector=gitWorkhorseSelector {
            code: { re: '^5.*' },
          },
        ),

        significantLabels: ['route_id', 'code'],

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

        monitoringThresholds+: {
          errorRatio: 0.999,
          apdexScore: 0.995,
        },
      },
    } + railsQueueingSli(0.05, 0.1),
})
