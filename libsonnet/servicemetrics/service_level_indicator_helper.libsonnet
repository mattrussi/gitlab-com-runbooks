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
      // cast value to array if not an array yet
      local selector = std.foldl(
        function(m, label)
          local value = if std.isArray(obj.value[label]) then
            obj.value[label]
          else
            [obj.value[label]];

          m { [label]: value },
        std.objectFields(obj.value),
        {}
      );

      // merge labels for the same metric
      if std.objectHas(memo, metricName) then
        memo {
          [metricName]: mergeSelector(memo[metricName], selector),
        }
      else
        memo {
          [metricName]: selector,
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
