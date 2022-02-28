local queryWithMeta(filter) =
  filter {
    meta+: {
      key: 'query',
      type: 'custom',
      value: std.toString(filter.query),
    },
  };

// Builds an ElasticSearch match filter clause
local matchFilter(field, value) =
  {
    query: {
      match: {
        [field]: {
          query: value,
          type: 'phrase',
        },
      },
    },
  };

local matchInFilter(field, possibleValues) =
  queryWithMeta({
    query: {
      bool: {
        should: [{ match_phrase: { [field]: possibleValue } } for possibleValue in possibleValues],
        minimum_should_match: 1,
      },
    },
  });

// Builds an ElasticSearch range filter clause
local rangeFilter(field, gteValue, lteValue) =
  {
    query: {
      range: {
        [field]: {
          [if gteValue != null then 'gte']: gteValue,
          [if lteValue != null then 'lte']: lteValue,
        },
      },
    },
  };

local existsFilter(field) =
  {
    exists: {
      field: field,
    },
  };

local mustNot(filter) =
  filter {
    meta+: {
      negate: true,
    },
  };

local matchAnyScriptFilter(scripts) = {
  query: {
    bool: {
      should: [
        { script: { script: { source: script } } }
        for script in scripts
      ],
      minimum_should_match: 1,
    },
  },
};

local matchObject(fieldName, matchInfo) =
  local gte = if std.objectHas(matchInfo, 'gte') then matchInfo.gte else null;
  local lte = if std.objectHas(matchInfo, 'lte') then matchInfo.lte else null;
  local values = std.prune([gte, lte]);

  if std.length(values) > 0 then
    rangeFilter(fieldName, gte, lte)
  else
    std.assertEqual(false, { __message__: 'Only gte and lte fields are supported but not in [%s]' % std.join(', ', std.objectFields(matchInfo)) });

local matcher(fieldName, matchInfo) =
  if fieldName == 'anyScript' && std.isArray(matchInfo) then
    matchAnyScriptFilter(matchInfo)
  else if std.isString(matchInfo) then
    matchFilter(fieldName, matchInfo)
  else if std.isArray(matchInfo) then
    matchInFilter(fieldName, matchInfo)
  else if std.isObject(matchInfo) then
    matchObject(fieldName, matchInfo);

local matchers(matches) =
  [
    matcher(k, matches[k])
    for k in std.objectFields(matches)
  ];


{
  matcher:: matcher,
  matchers:: matchers,
  matchFilter:: matchFilter,
  existsFilter:: existsFilter,
  rangeFilter:: rangeFilter,
  mustNot:: mustNot,
}
