local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local rateMetric = metricsCatalog.rateMetric;

metricsCatalog.serviceDefinition({
  type: 'waf',
  tier: 'lb',
  monitoringThresholds: {
    errorRatio: 0.999,
  },
  serviceDependencies: {
    frontend: true,
  },
  provisioning: {
    kubernetes: false,
    vms: false,
  },
  serviceLevelIndicators: {
    gitlab_zone: {
      featureCategory: 'not_owned',
      teams: ['sre_coreinfra'],
      description: |||
        Aggregation of all public traffic for GitLab.com passing through the WAF.

        Errors on this SLI may indicate that the WAF has detected
        malicious traffic and is blocking it. It may also indicate
        serious upstream failures on GitLab.com.
      |||,

      requestRate: rateMetric(
        counter='cloudflare_zones_http_responses_total',
        selector='zone=~"gitlab.com|staging.gitlab.com"'
      ),

      errorRate: rateMetric(
        counter='cloudflare_zones_http_responses_total',
        selector='zone=~"gitlab.com|staging.gitlab.com", edge_response_status=~"5.."',
      ),

      significantLabels: [],
    },
    // The "gitlab.net" zone
    gitlab_net_zone: {
      featureCategory: 'not_owned',
      teams: ['sre_coreinfra'],
      description: |||
        Aggregation of all GitLab.net (non-pulic) traffic passing through the WAF.

        Errors on this SLI may indicate that the WAF has detected
        malicious traffic and is blocking it.
      |||,

      requestRate: rateMetric(
        counter='cloudflare_zones_http_responses_total',
        selector='zone="gitlab.net"'
      ),

      errorRate: rateMetric(
        counter='cloudflare_zones_http_responses_total',
        selector='zone="gitlab.net", edge_response_status=~"5.."',
      ),

      significantLabels: [],
    },
  },
})
