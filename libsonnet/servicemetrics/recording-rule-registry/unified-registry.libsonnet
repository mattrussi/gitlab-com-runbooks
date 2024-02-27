local monitoredServices = (import 'gitlab-metrics-config.libsonnet').monitoredServices;
local aggregationSets = (import 'gitlab-metrics-config.libsonnet').aggregationSets;
local aggregationSet = import 'servicemetrics/aggregation-set.libsonnet';
local sliMetricDescriptor = import 'servicemetrics/sli_metric_descriptor.libsonnet';
local selectors = import 'promql/selectors.libsonnet';
local aggregations = import 'promql/aggregations.libsonnet';
local optionalOffset = import 'recording-rules/lib/optional-offset.libsonnet';

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
            injectAggregationSetLabels(sliMetricDescriptor.sliMetricsDescriptor(sli).metricNamesAndAggregationLabels())
            for sli in serviceDefinition.listServiceLevelIndicators()
          ]
        ),
      },
    monitoredServices,
    {}
  );

local injectType(metricAndSelectorHash, typeArray) = std.foldl(
  function(memo, metric)
    memo {
      [metric]+: { type: { oneOf: typeArray } },
    },
  std.objectFields(metricAndSelectorHash),
  metricAndSelectorHash
);

local getMetricsAndSelectors(serviceDefinition) =
  local slis = serviceDefinition.listServiceLevelIndicators();
  local withEmittedBy = std.map(
    function(sli)
      local metricAndSelectors = sliMetricDescriptor.sliMetricsDescriptor(sli).metricNamesAndSelectors();
      injectType(metricAndSelectors, sli.emittedBy),
    std.filter(
      function(sli) sli.emittedBy != [],
      slis
    )
  );
  local withoutEmittedBy = [
    sliMetricDescriptor.sliMetricsDescriptor(sli).metricNamesAndSelectors()
    for sli in slis
    if sli.emittedBy == []
  ];

  sliMetricDescriptor.collectMetricNamesAndSelectors(withEmittedBy + withoutEmittedBy);


local recordedMetricNamesAndSelectorsByType = std.foldl(
  function(memo, serviceDefinition)
    memo { [serviceDefinition.type]: getMetricsAndSelectors(serviceDefinition) },
  monitoredServices,
  {}
);

local recordingRuleExpressionFor(metricName, labels, selector, burnRate) =
  local query = 'rate(%(metricName)s{%(selector)s}[%(rangeInterval)s] offset 30s)' % {
    metricName: metricName,
    rangeInterval: burnRate,
    selector: selectors.serializeHash(selector),
  };
  aggregations.aggregateOverQuery('sum', std.set(labels), query);

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

  rulesForServiceForBurnRate(serviceType, burnRate, extraSelector)::
    local metricsAndLabels = recordedMetricNamesAndLabelsByType[serviceType];
    local metricsAndSelectors = recordedMetricNamesAndSelectorsByType[serviceType];
    local allMetrics = std.setUnion(std.objectFields(metricsAndLabels), std.objectFields(metricsAndSelectors));
    std.map(
      function(metricName)
        local labels = metricsAndLabels[metricName];
        local selector = selectors.merge(metricsAndSelectors[metricName], extraSelector);
        generateRecordingRulesForMetric(metricName, labels, selector, burnRate),
      allMetrics
    ),

  recordingRuleForMetricAtBurnRate(metricName, rangeInterval)::
    local metricNames = std.flatMap(std.objectFields, std.objectValues(recordedMetricNamesAndLabelsByType));

    std.setMember(metricName, metricNames),

  recordingRuleNameFor: recordingRuleNameFor,
}
