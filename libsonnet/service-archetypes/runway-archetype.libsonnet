local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local gaugeMetric = metricsCatalog.gaugeMetric;
local toolingLinks = import 'toolinglinks/toolinglinks.libsonnet';

// Default SLIs/SLOs for Runway services
function(
  type,
  team,
  apdexScore=0.999,
  errorRatio=0.999,
  apdexSatisfiedThreshold="1067.1895716335973",
  featureCategory='not_owned',
  userImpacting=true,
  trafficCessationAlertConfig=true,
  severity='s4',
  customToolingLinks=[]
)
  local baseSelector = { type: type };
  {
    type: type,
    tier: 'sv',

    monitoringThresholds: {
      apdexScore: apdexScore,
      errorRatio: errorRatio,
    },

    provisioning: {
      vms: false,
      kubernetes: false,
      runway: true,
    },

    // Runway splits traffic between multiple revisions for canary deployments
    serviceIsStageless: true,
    dangerouslyThanosEvaluated: true,

    serviceLevelIndicators: {
      runway_ingress: {
        description: |||
          Application load balancer serving ingress HTTP requests for the Runway service.
        |||,

        apdex: histogramApdex(
          histogram='stackdriver_cloud_run_revision_run_googleapis_com_request_latencies_bucket',
          rangeVectorFunction='avg_over_time',
          selector=baseSelector,
          satisfiedThreshold=apdexSatisfiedThreshold,
          unit='ms',
        ),

        requestRate: gaugeMetric(
          gauge='stackdriver_cloud_run_revision_run_googleapis_com_request_count',
          selector=baseSelector,
          samplingInterval=60, //seconds. See https://cloud.google.com/monitoring/api/metrics_gcp#run/request_count
        ),

        errorRate: gaugeMetric(
          gauge='stackdriver_cloud_run_revision_run_googleapis_com_request_count',
          selector=baseSelector { response_code_class: '5xx' },
          samplingInterval=60,
        ),

        significantLabels: ['revision_name', 'response_code'],

        userImpacting: userImpacting,

        trafficCessationAlertConfig: trafficCessationAlertConfig,

        team: team,

        featureCategory: featureCategory,

        severity: severity,

        toolingLinks: [
          toolingLinks.googleCloudRun(
            serviceName=type,
            project='gitlab-runway-production',
            gcpRegion='us-east1'
          ),
        ] + customToolingLinks,
      },
    },

    skippedMaturityCriteria: {
      'Structured logs available in Kibana': 'Runway structured logs are temporarily available in Stackdriver',
      'Service exists in the dependency graph': 'Runway services are deployed outside of the monolith',
    },
  }
