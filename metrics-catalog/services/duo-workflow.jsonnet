local runwayArchetype = import 'service-archetypes/runway-archetype.libsonnet';
local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local rateMetric = metricsCatalog.rateMetric;
local runwayHelper = import 'service-archetypes/helpers/runway.libsonnet';

local baseSelector = { type: 'duo-workflow' };

metricsCatalog.serviceDefinition(
  runwayArchetype(
    type='duo-workflow',
    team='duo_workflow',
    severity='s4',
    featureCategory='duo_workflow',
    apdexScore=0.95,
    errorRatio=0.95,
    externalLoadBalancer=true,
  )
  {
    local runwayLabels = runwayHelper.labels(self),
    local commonServerLabels = [
      'grpc_code',
      'grpc_method',
      'grpc_service',
    ] + runwayLabels,

    serviceLevelIndicators+: {
      server: {
        severity: 's4',
        userImpacting: true,
        featureCategory: 'duo_workflow',
        useConfidenceLevelForSLIAlerts: '98%',
        description: |||
          This SLI monitors all Duo Workflow GRPC requests.
          GRPC failures which are considered to be the "server's fault" are counted as errors.
        |||,

        monitoringThresholds: {
          apdexScore: 0.95,
          errorRatio: 0.95,
        },

        requestRate: rateMetric(
          counter='grpc_server_handled_total',
          selector=baseSelector
        ),

        errorRate: rateMetric(
          counter='grpc_server_handled_total',
          selector=baseSelector {
            grpc_code: { noneOf: ['OK'] },
          }
        ),

        significantLabels: commonServerLabels,
      },
    },
  },
)
