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

local mergeSelector(from, to) =
  std.foldl(
    function(memo, label)
      if std.objectHas(from, label) && std.objectHas(to, label) then
        memo {
          [label]: std.setUnion(from[label], to[label]),
        }
      else if std.objectHas(from, label) then
        memo {
          [label]: from[label],
        }
      else
        memo {
          [label]: to[label],
        },
    std.setUnion(std.objectFields(from), std.objectFields(to)),
    {}
  );

// input: array of hashes [ {metric: { label: value } ] or [ {metric: { label: [value] } ]
// output: merged label selectors in a hash { metric: { label: [value] } }
local collectMetricNamesAndSelectors(metricSelectors) =
  std.foldl(
    function(memo, obj)
      local metricName = obj.key;
      local selectorHash = obj.value;
      // cast value to array if not an array yet
      local selectorHashWithArrayValues = std.foldl(
        function(m, label)
          if std.isArray(selectorHash[label]) then
            m { [label]: selectorHash[label] }
          else if std.isObject(selectorHash[label]) then
            // ignore object selector for now, eg { code: { re: '^5.*' } }
            // we're only interested in type selector which is usually a simple string value, eg { type: 'web' }
            m
          else
            m { [label]: [selectorHash[label]] },
        std.objectFields(selectorHash),
        {}
      );

      // merge labels for the same metric
      if std.objectHas(memo, metricName) then
        memo {
          [metricName]: mergeSelector(memo[metricName], selectorHashWithArrayValues),
        }
      else
        memo {
          [metricName]: selectorHashWithArrayValues,
        },
    std.flatMap(
      function(ms)
        std.objectKeysValues(ms),
      metricSelectors
    ),
    {}
  );

{
  collectMetricNamesAndLabels: collectMetricNamesAndLabels,
  collectMetricNamesAndSelectors: collectMetricNamesAndSelectors,
}
