local sliDefinition = import 'gitlab-slis/sli-definition.libsonnet';
local aggregationSet = import 'servicemetrics/aggregation-set.libsonnet';
local defaultLabels = ['environment', 'tier', 'type', 'stage'];

local aggregationFormats(sli) =
  if sli.kind == sliDefinition.apdexKind then
    local format = { sliName: sli.name, burnRate: '%s' };
    {
      apdexSuccessRate: 'gitlab_sli_aggregation:%(sliName)s:apdex:success:rate_%(burnRate)s' % format,
      apdexWeight: 'gitlab_sli_aggregation:%(sliName)s:apdex:weight:score_%(burnRate)s' % format,
    }
  else
    assert false : '%s is using unsupported SLI kind: %s' % [sli.name, sli.kind];
    [];

local sourceAggregationSet(sli) =
  aggregationSet.AggregationSet({
    id: 'source_application_sli_%s' % sli.name,
    name: 'Application Defined SLI Source metrics: %s' % sli.name,
    labels: defaultLabels + sli.significantLabels,
    intermediateSource: true,
    selector: { monitor: { ne: 'global' } },
    supportedBurnRates: ['5m', '1h'],
    metricFormats: aggregationFormats(sli),
  });

local targetAggregationSet(sli) =
  aggregationSet.AggregationSet({
    id: 'global_application_sli_%s' % sli.name,
    name: 'Application Defined SLI Global metrics: %s' % sli.name,
    labels: defaultLabels + sli.significantLabels,
    intermediateSource: true,
    selector: { monitor: 'global' },
    supportedBurnRates: ['5m', '1h'],
    metricFormats: aggregationFormats(sli),
  });

{
  sourceAggregationSet(sli):: sourceAggregationSet(sli),
  targetAggregationSet(sli):: targetAggregationSet(sli),
}
