// input: array of hashes [ {metric: set(labels)} ]
// output: merged labels in a hash { metric: set(labels) }
local collectMetricNamesAndLabels(metricLabels) =
  std.foldl(
    function(memo, obj)
      // merge labels for the same metric
      if std.objectHas(memo, obj.key) then
        memo {
          [obj.key]: std.setUnion(memo[obj.key], obj.value),
        }
      else
        memo {
          [obj.key]: obj.value,
        },
    std.flatMap(
      function(ml)
        std.objectKeysValues(ml),
      metricLabels
    ),
    {}
  );

local normalizeSelectorExpression(exp) =
  // This function only takes positive expression ('eq', 're', 'oneOf') and turns them into { oneOf: array } form.
  // Negative expressions ('ne', 'nre', 'noneOf') are ignored.
  // When selecting for negative values in an SLI selector, we can ignore the selector
  // for the recording rule registry and include these metrics in the aggregation to filter
  // them out in the recording rules for the aggregation set.
  // Examples:
  // 'a'                => { oneOf: ['a'] }
  // { eq: 'a' }        => { oneOf: ['a'] }
  // { re: 'a|b' }      => { oneOf: ['a', 'b'] }
  // { oneOf: ['a'] }   => { oneOf: ['a'] }
  // { ne: 'a' }        => {}
  // { nre: 'a' }       => {}
  // { noneOf: ['a'] }  => {}
  if std.isObject(exp) then
    std.foldl(
      function(memo, keyword)
        local base = std.get(memo, 'oneOf', []);
        if keyword == 'eq' then
          memo {
            oneOf: std.setUnion(base, [exp[keyword]]),
          }
        else if keyword == 're' then
          memo {
            oneOf: std.setUnion(base, std.split(exp[keyword], '|')),
          }
        else if keyword == 'oneOf' then
          memo {
            oneOf: std.setUnion(base, exp[keyword]),
          }
        else if std.member(['ne', 'nre', 'noneOf'], keyword) then memo
        else assert false : 'Unknown selector keyword: %s' % [keyword];
             {},
      std.objectFields(exp),
      {}
    )
  else if std.isArray(exp) then
    local normalizedArr = [normalizeSelectorExpression(e) for e in exp];
    std.foldl(
      function(memo, obj)
        memo {
          oneOf: std.setUnion(
            std.get(memo, 'oneOf', []),
            std.get(obj, 'oneOf', []),
          ),
        },
      normalizedArr,
      {}
    )
  else
    { oneOf: [exp] };

local normalize(selector) =
  std.foldl(
    function(memo, key)
      local value = selector[key];
      memo { [key]: normalizeSelectorExpression(value) },
    std.objectFields(selector),
    {}
  );

local mergeSelector(from, to) =
  local normalizedFrom = normalize(from);
  local normalizedTo = normalize(to);
  std.foldl(
    function(memo, label)
      if std.objectHas(from, label) && std.objectHas(to, label) then
        memo {
          [label]: {
            oneOf: std.setUnion(
              std.get(normalizedFrom[label], 'oneOf', []),
              std.get(normalizedTo[label], 'oneOf', []),
            ),
          },
        }
      else if std.objectHas(from, label) then
        memo {
          [label]: normalizedFrom[label],
        }
      else
        memo {
          [label]: normalizedTo[label],
        },
    std.setUnion(std.objectFields(normalizedFrom), std.objectFields(normalizedTo)),
    {}
  );

local isCombinedSli(sliDefinition) = std.objectHas(sliDefinition, 'components');

// input: array of hashes [ {metric: { label: value } ]
// output: merged label selectors in a hash { metric: { label: {oneOf: [value] } } }
local collectMetricNamesAndSelectors(metricSelectors) =
  std.foldl(
    function(memo, obj)
      local metricName = obj.key;
      local selectorHash = obj.value;
      memo {
        [metricName]: mergeSelector(
          std.get(memo, metricName, {}),
          selectorHash
        ),
      },
    std.flatMap(
      function(ms)
        std.objectKeysValues(ms),
      metricSelectors
    ),
    {}
  );

// Return a hash of { metric: set(labels) } from all defined metrics
local generateMetricNamesAndAggregationLabels(sliDefinition) =
  local metricsAndLabels = if isCombinedSli(sliDefinition) then
    [generateMetricNamesAndAggregationLabels(component) for component in sliDefinition.components]
  else
    local apdexMetricsAndLabels =
      if sliDefinition.hasApdex() && std.objectHasAll(sliDefinition.apdex, 'supportsReflection') then
        sliDefinition.apdex.supportsReflection().getMetricNamesAndLabels()
      else
        {};

    local requestRateMetricsAndLabels =
      if std.objectHasAll(sliDefinition.requestRate, 'supportsReflection') then
        sliDefinition.requestRate.supportsReflection().getMetricNamesAndLabels()
      else
        {};

    local errorRateMetricsAndLabels =
      if sliDefinition.hasErrorRate() && std.objectHasAll(sliDefinition.errorRate, 'supportsReflection') then
        sliDefinition.errorRate.supportsReflection().getMetricNamesAndLabels()
      else
        {};
    [apdexMetricsAndLabels, requestRateMetricsAndLabels, errorRateMetricsAndLabels];

  local metricNamesAndLabels = collectMetricNamesAndLabels(metricsAndLabels);
  std.foldl(
    function(memo, metric)
      memo {
        [metric]: std.setUnion(
          metricNamesAndLabels[metric],
          std.set(sliDefinition.significantLabels)
        ),
      },
    std.objectFields(metricNamesAndLabels),
    {}
  );

// Return a hash of { metric: { label: { oneOf: [value] } } } from all defined metrics
local generateMetricNamesAndSelectors(sliDefinition) =
  local metricsAndSelectors = if isCombinedSli(sliDefinition) then
    [generateMetricNamesAndSelectors(component) for component in sliDefinition.components]
  else
    local apdexMetricsAndSelectors =
      if sliDefinition.hasApdex() && std.objectHasAll(sliDefinition.apdex, 'supportsReflection') then
        sliDefinition.apdex.supportsReflection().getMetricNamesAndSelectors()
      else
        {};

    local requestRateMetricsAndSelectors =
      if std.objectHasAll(sliDefinition.requestRate, 'supportsReflection') then
        sliDefinition.requestRate.supportsReflection().getMetricNamesAndSelectors()
      else
        {};

    local errorRateMetricsAndSelectors =
      if sliDefinition.hasErrorRate() && std.objectHasAll(sliDefinition.errorRate, 'supportsReflection') then
        sliDefinition.errorRate.supportsReflection().getMetricNamesAndSelectors()
      else
        {};
    [apdexMetricsAndSelectors, requestRateMetricsAndSelectors, errorRateMetricsAndSelectors];

  collectMetricNamesAndSelectors(metricsAndSelectors);

{
  collectMetricNamesAndLabels: collectMetricNamesAndLabels,
  collectMetricNamesAndSelectors: collectMetricNamesAndSelectors,

  sliMetricsDescriptor(sliDefinition):: {
    metricNamesAndAggregationLabels():: generateMetricNamesAndAggregationLabels(sliDefinition),

    metricNamesAndSelectors():: generateMetricNamesAndSelectors(sliDefinition),
  },

  // only for testing
  _normalizeSelectorExpression: normalizeSelectorExpression,
  _normalize: normalize,
  _mergeSelector: mergeSelector,
}
