local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local rateMetric = metricsCatalog.rateMetric;
local toolingLinks = import 'toolinglinks/toolinglinks.libsonnet';
local serviceCatalog = import 'service-catalog/service-catalog.libsonnet';

local uniqEnvValues(environments, field) = std.set(std.map(function(env) env[field], environments));

// Default CloudFlare worker SLIs
function(
  type,
  team,
  environments=[{
    tenant: 'gitlab-ops',
    env: 'gprd',
    scriptEnvironment: 'production',
  }, {
    tenant: 'gitlab-ops',
    env: 'gstg',
    scriptEnvironment: 'staging',
  }],
  errorRatio=0.999,
  featureCategory='not_owned',
  userImpacting=true,
  trafficCessationAlertConfig=true,
  severity='s3',
  // Additional tooling links
  customToolingLinks=[],
)
  local serviceCatalogEntry = serviceCatalog.lookupService(type);

  {
    type: type,
    tier: 'lb',

    tags: ['cloudflare-worker'],

    tenants: uniqEnvValues(environments, 'tenant'),
    tenantEnvironmentTargets: uniqEnvValues(environments, 'env'),

    monitoringThresholds: {
      errorRatio: errorRatio,
    },

    provisioning: {
      vms: false,
      kubernetes: false,
      runway: false,
    },

    serviceIsStageless: true,

    serviceLevelIndicators: {
      worker_requests: {
        description: |||
          Aggregation of requests that are flowing through `%(type)s`.

          Errors on this SLI may indicate issues within the deployed `%(type)s`
          codebase as errors are limited to those originating inside of the worker.

          %(sreGuide)s
        ||| % {
          type: type,
          sreGuide: (
            if (
              // We have a service
              (serviceCatalogEntry != null) &&
              // We have an SRE guide set
              (std.get(serviceCatalogEntry.technical.documents, 'sre_guide', null) != null)
            )
            then 'See: %s' % serviceCatalogEntry.technical.documents.sre_guide
            else ''
          ),
        },

        requestRate: rateMetric(
          counter='cloudflare_worker_requests_count',
        ),
        errorRate: rateMetric(
          counter='cloudflare_worker_errors_count',
        ),

        significantLabels: ['script_name'],

        userImpacting: userImpacting,
        trafficCessationAlertConfig: trafficCessationAlertConfig,
        team: team,
        featureCategory: featureCategory,
        severity: severity,
        toolingLinks:
          [
            toolingLinks.serviceCatalogLogging(type)
          ] +
          customToolingLinks,
      },
    },

    skippedMaturityCriteria: {
      'Structured logs available in Kibana': 'Logs from CloudFlare workers are stored and accessible in CloudFlare through the UI. See https://developers.cloudflare.com/workers/observability/logs/workers-logs/',
      'Service exists in the dependency graph': 'CloudFlare worker services are deployed outside of the monolith',
    },
  }
