local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local rateMetric = metricsCatalog.rateMetric;

metricsCatalog.serviceDefinition({
  type: 'waf',
  tier: 'lb',
  tenants: [ 'gitlab-gprd', 'gitlab-gstg', 'gitlab-pre' ],
  monitoringThresholds: {
    // Error SLO disabled as monitoring data is unreliable.
    // See: https://gitlab.com/gitlab-com/gl-infra/production/-/issues/5465
    //errorRatio: 0.999,
  },
  serviceDependencies: {
    frontend: true,
    nat: true,
  },
  provisioning: {
    kubernetes: false,
    vms: false,
  },

  // No stages for Thanos
  serviceIsStageless: true,

  serviceLevelIndicators: {
    gitlab_zone: {
      severity: 's3',
      team: 'reliability_foundations',
      userImpacting: false,  // Low until CF exporter metric quality increases https://gitlab.com/gitlab-com/gl-infra/reliability/-/issues/10294
      featureCategory: 'not_owned',
      description: |||
        Aggregation of all public traffic for GitLab.com passing through the WAF.

        Errors on this SLI may indicate that the WAF has detected
        malicious traffic and is blocking it. It may also indicate
        serious upstream failures on GitLab.com.
      |||,

      local zoneSelector = { zone: { re: 'gitlab.com|staging.gitlab.com' } },
      requestRate: rateMetric(
        counter='cloudflare_zone_requests_total',
        selector=zoneSelector
      ),

      errorRate: rateMetric(
        counter='cloudflare_zone_requests_status',
        selector=zoneSelector {
          status: { re: '5..' },
        },
      ),

      significantLabels: [],
    },
    // The "gitlab.net" zone
    gitlab_net_zone: {
      severity: 's3',
      team: 'reliability_foundations',
      userImpacting: false,  // Low until CF exporter metric quality increases https://gitlab.com/gitlab-com/gl-infra/reliability/-/issues/10294
      featureCategory: 'not_owned',
      description: |||
        Aggregation of all GitLab.net (non-pulic) traffic passing through the WAF.

        Errors on this SLI may indicate that the WAF has detected
        malicious traffic and is blocking it.
      |||,

      local zoneSelector = { zone: 'gitlab.net' },

      requestRate: rateMetric(
        counter='cloudflare_zone_requests_total',
        selector=zoneSelector
      ),

      errorRate: rateMetric(
        counter='cloudflare_zone_requests_status',
        selector=zoneSelector {
          status: { re: '5..' },
        },
      ),

      significantLabels: [],
    },
  },
  skippedMaturityCriteria: {
    'Developer guides exist in developer documentation': 'WAF is an infrastructure component, powered by Cloudflare',
    'Structured logs available in Kibana': 'Logs from CloudFlare are pushed to a GCS bucket by CloudFlare, and not ingested to ElasticSearch due to volume.  See https://gitlab.com/gitlab-com/runbooks/-/blob/master/docs/cloudflare/logging.md for alternatives',
  },
})
