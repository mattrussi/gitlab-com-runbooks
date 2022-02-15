local test = import 'github.com/yugui/jsonnetunit/jsonnetunit/test.libsonnet';
local matcher = import 'jsonnetunit/matcher.libsonnet';
local objects = import 'utils/objects.libsonnet';

local matchers = {
  expectUniqueMappings: {
    matcher(actual, mappingFn):
      matcher {
        local mappings = std.foldl(
          function(object, item)
            local key = mappingFn(item);
            local value = if std.objectHas(object, key) then object[key] + [item] else [item];

            object { [key]: value },
          actual,
          {}
        ),
        local duplicates = std.filter(function(item) std.length(item[1]) > 1, objects.toPairs(mappings)),

        satisfied: std.length(duplicates) == 0,
        positiveMessage: 'Expected to have a unique mapping. Duplicates found: %s' % [objects.fromPairs(duplicates)],
      },
    expectationType: true,
  },
  expectAll: {
    matcher(actual, f):
      matcher {
        local notSatisfied = std.filter(function(e) !f(e), actual),
        satisfied: std.length(notSatisfied) == 0,
        positiveMessage: 'Expected all elements to satisfy function but %s did not' % [notSatisfied],
      },
    expectationType: true,
  },
};

{
  suite(tests): test.suite(tests) { matchers+: matchers },
}
