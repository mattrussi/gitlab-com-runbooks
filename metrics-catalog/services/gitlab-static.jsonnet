local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local rateMetric = metricsCatalog.rateMetric;
local toolingLinks = import 'toolinglinks/toolinglinks.libsonnet';

metricsCatalog.serviceDefinition({
  type: 'gitlab-static',
  tier: 'inf',
  monitoringThresholds: {},
  serviceDependencies: {},
  provisioning: {
    kubernetes: false,
    vms: false,
  },

  serviceIsStageless: true,

  serviceLevelIndicators: {
    gitlab_static_net_zone: {
      severity: 's3',
      team: 'reliability_general',
      userImpacting: true,
      featureCategory: 'not_owned',
      description: |||
        Aggregation of all public traffic for gitlab-static.net.

        Errors on this SLI *may* indicate that the WAF has detected
        malicious traffic and is blocking it or upstream errors
        processing the request.
      |||,

      local zoneSelector = { zone: 'gitlab-static.net' },
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

    web_ide_worker: {
      severity: 's3',
      team: 'reliability_general',
      userImpacting: true,
      featureCategory: 'web_ide',
      description: |||
        Cloudflare Worker used by our VS Code-based Web IDE to pull assets from *.cdn.web-ide.gitlab-static.net.
      |||,

      local workerSelector = { script_name: 'gitlab-web-ide-vscode-production' },
      requestRate: rateMetric(
        counter='cloudflare_worker_requests_count',
        selector=workerSelector
      ),

      errorRate: rateMetric(
        counter='cloudflare_worker_errors_count',
        selector=workerSelector
      ),

      significantLabels: [],
    },
  },
  skippedMaturityCriteria: {
    'Structured logs available in Kibana': 'Logs from CloudFlare workers are available on-demand but they are not being ingested due to volume',
    'Service exists in the dependency graph': 'This service is hosted by Cloudflare and does not depend on any other service',
  },
})
