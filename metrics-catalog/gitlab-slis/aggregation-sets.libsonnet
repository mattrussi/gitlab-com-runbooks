local sliDefinition = import 'gitlab-slis/sli-definition.libsonnet';
local aggregationSet = import 'servicemetrics/aggregation-set.libsonnet';
local recordingRuleRegistry = import 'servicemetrics/recording-rule-registry.libsonnet';

local defaultLabels = ['environment', 'tier', 'type', 'stage'];
local globalLabels = ['env'];
local supportedBurnRates = ['5m', '1h'];

local resolvedRecording(metric, labels, burnRate) =
  assert recordingRuleRegistry.resolveRecordingRuleFor(
    metricName=metric, aggregationLabels=labels, rangeInterval=burnRate
  ) != null : 'No previous recording found for %s and burn rate %s' % [metric, burnRate];
  recordingRuleRegistry.recordingRuleNameFor(metric, burnRate);

local recordedBurnRatesForSLI(sli) =
  std.foldl(
    function(memo, burnRate)
      memo {
        [burnRate]: {
          apdexSuccessRate: resolvedRecording(sli.successCounterName, sli.significantLabels, burnRate),
          apdexWeight: resolvedRecording(sli.totalCounterName, sli.significantLabels, burnRate),
        },
      },
    supportedBurnRates,
    {}
  );

local aggregationFormats(sli) =
  local format = { sliName: sli.name, burnRate: '%s' };
  {
    apdexSuccessRate: 'application_sli_aggregation:%(sliName)s:apdex:success:rate_%(burnRate)s' % format,
    apdexWeight: 'application_sli_aggregation:%(sliName)s:apdex:weight:score_%(burnRate)s' % format,
  };

local sourceAggregationSet(sli) =
  aggregationSet.AggregationSet(
    {
      id: 'source_application_sli_%s' % sli.name,
      name: 'Application Defined SLI Source metrics: %s' % sli.name,
      labels: defaultLabels + sli.significantLabels,
      intermediateSource: true,
      selector: { monitor: { ne: 'global' } },
      supportedBurnRates: supportedBurnRates,
    }
    +
    if sli.inRecordingRuleRegistry then
      { burnRates: recordedBurnRatesForSLI(sli) }
    else
      { metricFormats: aggregationFormats(sli) }
  );

local targetAggregationSet(sli) =
  aggregationSet.AggregationSet({
    id: 'global_application_sli_%s' % sli.name,
    name: 'Application Defined SLI Global metrics: %s' % sli.name,
    labels: globalLabels + defaultLabels + sli.significantLabels,
    intermediateSource: false,
    selector: { monitor: 'global' },
    supportedBurnRates: ['5m', '1h'],
    metricFormats: aggregationFormats(sli),
  });

{
  sourceAggregationSet(sli):: sourceAggregationSet(sli),
  targetAggregationSet(sli):: targetAggregationSet(sli),
}
