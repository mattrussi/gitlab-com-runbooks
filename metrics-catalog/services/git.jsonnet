local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local rateMetric = metricsCatalog.rateMetric;
local customRateQuery = metricsCatalog.customRateQuery;
local toolingLinks = import 'toolinglinks/toolinglinks.libsonnet';
local haproxyComponents = import './lib/haproxy_components.libsonnet';
local sliLibrary = import 'gitlab-slis/library.libsonnet';

local gitWorkhorseJobNameSelector = { job: { re: 'gitlab-workhorse|gitlab-workhorse-git' } };

metricsCatalog.serviceDefinition({
  type: 'git',
  tier: 'sv',

  tags: ['golang'],

  contractualThresholds: {
    apdexRatio: 0.95,
    errorRatio: 0.005,
  },
  monitoringThresholds: {
    apdexScore: 0.998,
    errorRatio: 0.9995,
  },
  otherThresholds: {
    // Deployment thresholds are optional, and when they are specified, they are
    // measured against the same multi-burn-rates as the monitoring indicators.
    // When a service is in violation, deployments may be blocked or may be rolled
    // back.
    deployment: {
      apdexScore: 0.9995,
      errorRatio: 0.9995,
    },

    mtbf: {
      apdexScore: 0.9997,
      errorRatio: 0.9999,
    },
  },
  serviceDependencies: {
    gitaly: true,
    'redis-sidekiq': true,
    'redis-cache': true,
    redis: true,
    patroni: true,
    pgbouncer: true,
    praefect: true,
    pvs: true,
    consul: true,
  },
  provisioning: {
    vms: false,
    kubernetes: true,
  },
  // Git service is spread across multiple regions, monitor it as such
  regional: true,
  kubeResources: {
    'gitlab-shell': {
      kind: 'Deployment',
      containers: [
        'gitlab-shell',
      ],
    },
    'git-https': {
      kind: 'Deployment',
      containers: [
        'gitlab-workhorse',
        'webservice',
      ],
    },
  },
  serviceLevelIndicators: {
    loadbalancer: haproxyComponents.haproxyHTTPLoadBalancer(
      userImpacting=true,
      featureCategory='not_owned',
      stageMappings={
        main: { backends: ['https_git'], toolingLinks: [
          toolingLinks.bigquery(title='Top http clients by number of requests, main stage, 10m', savedQuery='805818759045:704c6bdf00a743d195d344306bf207ee'),
        ] },
        cny: { backends: ['canary_https_git'], toolingLinks: [
          toolingLinks.bigquery(title='Top http clients by number of requests, cny stage, 10m', savedQuery='805818759045:dea839bd669e41b5bc264c510294bb9f'),
        ] },  // What happens to cny websocket traffic?
      },
      selector={ type: 'frontend' },
      // Load balancer is single region
      regional=false
    ),

    loadbalancer_ssh: haproxyComponents.haproxyL4LoadBalancer(
      userImpacting=true,
      featureCategory='not_owned',
      stageMappings={
        main: {
          backends: ['ssh', 'altssh'],
          toolingLinks: [
            toolingLinks.bigquery(title='Top ssh clients by number of requests, 10m', savedQuery='805818759045:8a185b18fafe4081bf9fbdb5354844f9'),
          ],
        },
        // No canary SSH for now
      },
      selector={ type: 'frontend' },
      // Load balancer is single region
      regional=false
    ),

    workhorse: {
      userImpacting: true,
      featureCategory: 'not_owned',
      team: 'workhorse',
      description: |||
        Monitors the Workhorse instance running in the Git fleet, via the HTTP interface. This SLI
        excludes API requests, which have their own SLI with tigher latency thresholds.
        Websocket connections are excluded from the apdex score.
      |||,

      local baseSelector = gitWorkhorseJobNameSelector {
        type: 'git',
        route: [{ ne: '^/-/health$' }, { ne: '^/-/(readiness|liveness)$' }, { ne: '^/api/' }, { ne: '\\\\A/api/v4/jobs/request\\\\z' }, { ne: '^/api/v4/jobs/request\\\\z' }],
      },

      apdex: histogramApdex(
        histogram='gitlab_workhorse_http_request_duration_seconds_bucket',
        selector=baseSelector {
          route+: [{
            ne: '^/([^/]+/){1,}[^/]+/-/jobs/[0-9]+/terminal.ws\\\\z',
          }, {
            ne: '^/([^/]+/){1,}[^/]+/-/environments/[0-9]+/terminal.ws\\\\z',
          }, {
            ne: '^/-/cable\\\\z',  // Exclude Websocket connections from apdex score
          }],
        },
        satisfiedThreshold=30,
        toleratedThreshold=60
      ),

      requestRate: rateMetric(
        counter='gitlab_workhorse_http_requests_total',
        selector=baseSelector
      ),

      errorRate: rateMetric(
        counter='gitlab_workhorse_http_requests_total',
        selector=baseSelector {
          code: { re: '^5.*' },
        }
      ),

      significantLabels: ['fqdn', 'route'],

      toolingLinks: [
        toolingLinks.continuousProfiler(service='workhorse-git'),
        toolingLinks.sentry(slug='gitlab/gitlab-workhorse-gitlabcom'),
        toolingLinks.kibana(title='Workhorse', index='workhorse', type='git', slowRequestSeconds=10),
      ],
    },

    /**
     * The API route on Workhorse is used exclusively for auth requests from
     * GitLab shell. As such, it has much more performant latency requirements
     * that other Git/Workhorse traffic
     */
    workhorse_auth_api: {
      userImpacting: true,
      featureCategory: 'not_owned',
      team: 'workhorse',
      description: |||
        Monitors Workhorse API endpoints, running in the Git fleet, via the HTTP interface.
        Workhorse API requests have much tigher latency requirements, as these requests originate in GitLab-Shell
        and are on the critical path for authentication of Git SSH commands.
      |||,

      local baseSelector = gitWorkhorseJobNameSelector {
        type: 'git',
        route: '^/api/',
      },

      apdex: histogramApdex(
        histogram='gitlab_workhorse_http_request_duration_seconds_bucket',
        selector=baseSelector,
        // Note: 1s is too slow for an auth request. This threshold should be lower
        satisfiedThreshold=1
      ),

      requestRate: rateMetric(
        counter='gitlab_workhorse_http_requests_total',
        selector=baseSelector
      ),

      errorRate: rateMetric(
        counter='gitlab_workhorse_http_requests_total',
        selector=baseSelector {
          code: { re: '^5.*' },
        }
      ),

      significantLabels: ['fqdn'],

      toolingLinks: [
        toolingLinks.continuousProfiler(service='workhorse-git'),
        toolingLinks.sentry(slug='gitlab/gitlab-workhorse-gitlabcom'),
        // TODO: filter kibana query on route once https://gitlab.com/gitlab-org/gitlab-workhorse/-/merge_requests/624 arrives
        toolingLinks.kibana(title='Workhorse', index='workhorse', type='git', slowRequestSeconds=10),
      ],
    },

    local railsSelector = { job: 'gitlab-rails', type: 'git' },
    puma: {
      userImpacting: true,
      featureCategory: 'not_owned',
      description: |||
        Monitors Rails endpoints, running in the Git fleet, via the HTTP interface.
      |||,

      requestRate: rateMetric(
        counter='http_requests_total',
        selector=railsSelector,
      ),

      errorRate: rateMetric(
        counter='http_requests_total',
        selector=railsSelector { status: { re: '5..' } }
      ),

      significantLabels: ['fqdn', 'method', 'feature_category'],

      toolingLinks: [
        // Improve sentry link once https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/532 arrives
        toolingLinks.sentry(slug='gitlab/gitlabcom', type='git', variables=['environment', 'stage']),
      ],
    },

    gitlab_shell: {
      userImpacting: true,
      featureCategory: 'not_owned',
      description: |||
        We monitor GitLab shell, using HAProxy SSH connection information.
      |||,

      staticLabels: {
        tier: 'sv',
        stage: 'main',
      },

      // Unfortunately we don't have a better way of measuring this at present,
      // so we rely on HAProxy metrics
      requestRate: customRateQuery(|||
        sum by (environment) (haproxy_backend_current_session_rate{backend=~"ssh|altssh"})
      |||),

      significantLabels: [],

      toolingLinks: [
        toolingLinks.kibana(title='GitLab Shell', index='shell'),
      ],
    },

    gitlab_sshd: {
      userImpacting: true,
      featureCategory: 'source_code_management',
      description: |||
        Monitors Gitlab-sshd, using the connections bucket, and http requests bucket.
      |||,

      local baseSelector = {
        type: 'git',
      },

      apdex: histogramApdex(
        histogram='gitlab_shell_sshd_connection_duration_seconds_bucket',
        selector=baseSelector,
        satisfiedThreshold=10,
        toleratedThreshold=20
      ),

      requestRate: rateMetric(
        counter='gitlab_shell_sshd_connection_duration_seconds_count',
        selector=baseSelector
      ),

      significantLabels: [],

      toolingLinks: [
        toolingLinks.kibana(title='GitLab Shell', index='shell'),
      ],
    },

    rails_requests:
      sliLibrary.get('rails_request_apdex').generateServiceLevelIndicator(railsSelector) {
        monitoringThresholds+: {
          apdexScore: 0.997,
        },

        toolingLinks: [
          // TODO: These need to be defined in the appliation SLI and built using
          // selectors using the appropriate fields
          // https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/1411
          toolingLinks.kibana(title='Rails', index='rails', type='git', slowRequestSeconds=1),
        ],
      },
  },
})
