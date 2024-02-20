local monitoredServices = (import 'gitlab-metrics-config.libsonnet').monitoredServices;
local intervalForDuration = import 'servicemetrics/interval-for-duration.libsonnet';
local sliMetricDescriptor = import 'servicemetrics/sli_metric_descriptor.libsonnet';
local aggregations = import 'promql/aggregations.libsonnet';
local selectorsUtil = import 'promql/selectors.libsonnet';
local separateMimirRecordingFiles = (import 'recording-rules/lib/mimir/separate-mimir-recording-files.libsonnet').separateMimirRecordingFiles;
local aggregationSet = import 'servicemetrics/aggregation-set.libsonnet';
local aggregationSets = (import 'gitlab-metrics-config.libsonnet').aggregationSets;

local defaultAggregationLabels = std.set(
  std.flatMap(
    function(set) set.labels,
    std.objectValues(aggregationSets)
  )
);

local recordingRuleExpressionFor(metricName, labels, selector, burnRate, serviceDefinition) =
  local allRequiredLabelsPlusStandards = std.setUnion(labels, defaultAggregationLabels);
  local query = 'rate(%(metricName)s{%(selector)s}[%(rangeInterval)s] offset 30s)' % {
    metricName: metricName,
    rangeInterval: burnRate,
    selector: selectorsUtil.serializeHash(selector),
  };
  aggregations.aggregateOverQuery('sum', allRequiredLabelsPlusStandards, query);

local recordingRuleNameFor(metricName, burnRate) =
  'sli_aggregations:%(metricName)s:rate_%(rangeInterval)s' % {
    metricName: metricName,
    rangeInterval: burnRate,
  };

local generateRecordingRulesForMetric(metricName, labels, selector, burnRate, serviceDefinition) =
  {
    record: recordingRuleNameFor(metricName, burnRate),
    expr: recordingRuleExpressionFor(metricName, labels, selector, burnRate, serviceDefinition),
  };


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


local rulesForServiceForBurnRate(serviceDefinition, burnRate, extraSelector) =
  local allMetricsAndLabels = sliMetricDescriptor.collectMetricNamesAndLabels([
    sliMetricDescriptor.sliMetricsDescriptor(sli).metricNamesAndAggregationLabels()
    for sli in serviceDefinition.listServiceLevelIndicators()
  ]);
  local allMetricsAndSelectors = getMetricsAndSelectors(serviceDefinition);
  local allMetrics = std.setUnion(std.objectFields(allMetricsAndLabels), std.objectFields(allMetricsAndSelectors));
  if std.length(allMetrics) > 0 then
    {
      name: 'SLI Aggregations: %s - %s burn-rate' % [serviceDefinition.type, burnRate],
      interval: intervalForDuration.intervalForDuration(burnRate),
      rules: std.map(
        function(metricName)
          local labels = allMetricsAndLabels[metricName];
          local selector = selectorsUtil.merge(allMetricsAndSelectors[metricName], extraSelector);
          generateRecordingRulesForMetric(
            metricName,
            labels,
            selector,
            burnRate,
            serviceDefinition
          ),
        allMetrics,
      ),
    } else null;

local rulesForService(serviceDefinition, extraSelector) =
  std.prune([
    rulesForServiceForBurnRate(serviceDefinition, burnRate, extraSelector)
    for burnRate in aggregationSet.defaultSourceBurnRates
  ]);

local outputPromYaml(groups) =
  std.manifestYamlDoc({
    groups: groups,
  });

local fileForService(service, extraSelector={}) =
  local ruleGroups = rulesForService(
    service,
    extraSelector
  );
  if std.length(ruleGroups) > 1 then
    {
      'sli-aggregations':
        outputPromYaml(ruleGroups),
    }
  else
    {};

std.foldl(
  function(memo, service)
    memo + separateMimirRecordingFiles(
      function(service, selector, _)
        fileForService(service, extraSelector=selector),
      service,
    ),
  monitoredServices,
  {}
)
