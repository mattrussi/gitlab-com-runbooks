local monitoredServices = (import 'gitlab-metrics-config.libsonnet').monitoredServices;
local aggregationSets = (import 'gitlab-metrics-config.libsonnet').aggregationSets;
local aggregationSet = import 'servicemetrics/aggregation-set.libsonnet';
local sliMetricDescriptor = import 'servicemetrics/sli_metric_descriptor.libsonnet';
local selectors = import 'promql/selectors.libsonnet';
local aggregations = import 'promql/aggregations.libsonnet';
local optionalOffset = import 'recording-rules/lib/optional-offset.libsonnet';
local metricsConfig = import 'gitlab-metrics-config.libsonnet';
local metricsCatalog = import 'servicemetrics/metrics-catalog.libsonnet';

local aggregationSetLabels = std.set(
  std.flatMap(
    function(set) set.labels,
    std.objectValues(aggregationSets)
  )
);

local injectAggregationSetLabels(metricAndLabelsHash) =
  std.foldl(
    function(memo, metric)
      memo { [metric]: std.setUnion(metricAndLabelsHash[metric], aggregationSetLabels) },
    std.objectFields(metricAndLabelsHash),
    {}
  );

local recordedMetricNamesAndLabelsByType =
  std.foldl(
    function(memo, serviceDefinition)
      memo {
        [serviceDefinition.type]: sliMetricDescriptor.collectMetricNamesAndLabels(
          [
            injectAggregationSetLabels(
              sliMetricDescriptor.sliMetricsDescriptor(serviceDefinition.listServiceLevelIndicators()).aggregationLabelsByMetric
            ),
          ]
        ),
      },
    monitoredServices,
    {}
  );

local recordingRuleExpressionFor(metricName, labels, selector, burnRate) =
  local query = 'rate(%(metricName)s{%(selector)s}[%(rangeInterval)s] offset 30s)' % {
    metricName: metricName,
    rangeInterval: burnRate,
    selector: selectors.serializeHash(selector),
  };
  aggregations.aggregateOverQuery('sum', std.setUnion(labels, aggregationSetLabels), query);

local recordingRuleNameFor(metricName, burnRate) =
  'sli_aggregations:%(metricName)s:rate_%(rangeInterval)s' % {
    metricName: metricName,
    rangeInterval: burnRate,
  };

local generateRecordingRulesForMetric(metricName, labels, selector, burnRate) =
  {
    record: recordingRuleNameFor(metricName, burnRate),
    expr: recordingRuleExpressionFor(metricName, labels, selector, burnRate),
  };

local resolveRecordingRuleFor(metricName, aggregationLabels, selector, rangeInterval) =
  // Recording rules can't handle `$__interval` or $__rate_interval variable ranges, so always resolve these as 5m
  local durationWithRecordingRule = if std.startsWith(rangeInterval, '$__') then '5m' else rangeInterval;
  assert std.setMember(durationWithRecordingRule, std.set(aggregationSet.defaultSourceBurnRates)) : 'unsupported burn rate: %s' % [rangeInterval];

  local allMetricNamesAndLabels = sliMetricDescriptor.collectMetricNamesAndLabels(std.objectValues(recordedMetricNamesAndLabelsByType));
  local recordedLabels = allMetricNamesAndLabels[metricName];

  // monitor is added in thanos, but not in prometheus.
  // In mimir it should not matter either as everything is global (but per tenant)
  local ignoredLabels = ['monitor'];
  local requiredLabelsWithIgnoredLabels = std.set(aggregationLabels + selectors.getLabels(selector));
  local requiredLabels = std.setDiff(requiredLabelsWithIgnoredLabels, ignoredLabels);

  local missingLabels = std.setDiff(requiredLabels, recordedLabels);
  assert std.length(missingLabels) == 0 : '%s labels are missing in the SLI aggregations for %s' % [missingLabels, metricName];

  '%(metricName)s{%(selector)s}' % {
    metricName: recordingRuleNameFor(metricName, rangeInterval),
    selector: selectors.serializeHash(selector),
  };


local recordingRulesForClusters(clusters, metricName, aggregationLabels, selector, burnRate) =
  if std.length(clusters) > 0 then
    std.map(
      function(cluster)
        local selectorWithCluster = selectors.merge(selector, { cluster: cluster });
        generateRecordingRulesForMetric(metricName, aggregationLabels, selectorWithCluster, burnRate),
      clusters
    )
  else
    [generateRecordingRulesForMetric(metricName, aggregationLabels, selector, burnRate)];

local recordingRulesForTypes(types, metricName, aggregationLabels, selector, burnRate) =
  std.flatMap(
    function(type)
      local serviceDefinition = metricsCatalog.getServiceOptional(type);
      local isKubeProvisioned = serviceDefinition != null && serviceDefinition.provisioning.kubernetes;
      local env = std.get(selector, 'env');
      local clusters = if env != null && isKubeProvisioned then
        std.get(metricsConfig.gkeClustersByEnvironment, env, default=[])
      else
        [];
      local selectorPerType = selectors.merge(
        selector,
        { type: { oneOf: [type] } }
      );
      recordingRulesForClusters(clusters, metricName, aggregationLabels, selectorPerType, burnRate),
    types
  );

local generateRecordingRules(sliDefinitions, burnRate, extraSelector) =
  local descriptor = sliMetricDescriptor.sliMetricsDescriptor(sliDefinitions);
  local aggregationLabelsByMetric = descriptor.aggregationLabelsByMetric;
  local selectorsByMetric = descriptor.selectorsByMetric;
  local emittingTypesByMetric = descriptor.emittingTypesByMetric;

  std.flatMap(
    function(metricName)
      local selector = selectors.merge(
        selectorsByMetric[metricName],
        extraSelector
      );
      local emittingTypes = emittingTypesByMetric[metricName];
      local aggregationLabels = aggregationLabelsByMetric[metricName];

      if std.length(emittingTypes) > 0 then
        recordingRulesForTypes(emittingTypes, metricName, aggregationLabels, selector, burnRate)
      else
        [generateRecordingRulesForMetric(metricName, aggregationLabels, selector, burnRate)],
    descriptor.allMetrics,
  );

{
  resolveRecordingRuleFor(
    aggregationFunction='sum',
    aggregationLabels=[],
    rangeVectorFunction='rate',
    metricName=null,
    rangeInterval='5m',
    selector={},
    offset=null
  )::
    if rangeVectorFunction != 'rate' then null
    else
      local resolvedRecordingRule = resolveRecordingRuleFor(metricName, aggregationLabels, selector, rangeInterval);
      local recordingRuleWithOffset = resolvedRecordingRule + optionalOffset(offset);
      if aggregationFunction == 'sum' then
        aggregations.aggregateOverQuery(aggregationFunction, aggregationLabels, recordingRuleWithOffset)
      else if aggregationFunction == null then
        recordingRuleWithOffset
      else
        assert false : 'unsupported aggregation %s' % [aggregationFunction];
        null,

  rulesForServiceForBurnRate(serviceDefinition, burnRate, extraSelector)::
    generateRecordingRules(
      serviceDefinition.listServiceLevelIndicators(),
      burnRate,
      extraSelector
    ),

  recordingRuleForMetricAtBurnRate(metricName, rangeInterval)::
    local metricNames = std.flatMap(std.objectFields, std.objectValues(recordedMetricNamesAndLabelsByType));

    std.setMember(metricName, metricNames),

  recordingRuleNameFor: recordingRuleNameFor,
}
