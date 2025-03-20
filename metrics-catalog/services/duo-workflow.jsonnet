local runwayArchetype = import 'service-archetypes/runway-archetype.libsonnet';
local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local rateMetric = metricsCatalog.rateMetric;
local runwayHelper = import 'service-archetypes/helpers/runway.libsonnet';

local baseSelector = { type: 'duo-workflow' };

metricsCatalog.serviceDefinition(
  runwayArchetype(
    type='duo-workflow',
    team='duo_workflow',
  )
  {
    local runwayLabels = runwayHelper.labels(self),
    local commonServerLabels = [
      'grpc_code',
    ] + runwayLabels,

    serviceLevelIndicators: {
      server: {
        userImpacting: true,
        featureCategory: 'duo_workflow',
        description: |||
          This SLI monitors all Duo Workflow GRPC requests.
          GRPC failures which are considered to be the "server's fault" are counted as errors.
        |||,

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
