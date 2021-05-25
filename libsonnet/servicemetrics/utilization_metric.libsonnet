local aggregations = import 'promql/aggregations.libsonnet';
local selectors = import 'promql/selectors.libsonnet';
local strings = import 'utils/strings.libsonnet';

local environmentLabels = ['environment', 'tier', 'type', 'stage'];

// Default values to apply to a utilization definition
local utilizationDefinitionDefaults = {
  staticLabels: {},
  queryFormatConfig: {},
  /* When topk is set we record the topk items */
  topk: null,
};

local getAllowedServiceApplicator(allowedList) =
  local allowedSet = std.set(allowedList);
  function(type) std.setMember(type, allowedSet);

local getDisallowedServiceApplicator(disallowedList) =
  local disallowedSet = std.set(disallowedList);
  function(type) !std.setMember(type, disallowedSet);

// Returns a function that returns a boolean to indicate whether a service
// applies for the provided definition
local getServiceApplicator(appliesTo) =
  if std.isArray(appliesTo) then
    getAllowedServiceApplicator(appliesTo)
  else
    getDisallowedServiceApplicator(appliesTo.allExcept);

local validateAndApplyDefaults(definition) =
  local validated =
    std.isString(definition.title) &&
    (std.isArray(definition.appliesTo) || std.isObject(definition.appliesTo)) &&
    std.isString(definition.description) &&
    std.isArray(definition.resourceLabels) &&
    std.isString(definition.query);

  // Apply defaults
  if validated then
    utilizationDefinitionDefaults + definition
  else
    std.assertEqual(definition, { __assert__: 'Resource definition is invalid' });

local utilizationMetric = function(options)
  local definition = validateAndApplyDefaults(options);
  local serviceApplicator = getServiceApplicator(definition.appliesTo);

  definition {
    getTypeFilter()::
      (
        if std.isArray(definition.appliesTo) then
          if std.length(definition.appliesTo) > 1 then
            { type: { re: std.join('|', definition.appliesTo) } }
          else
            { type: definition.appliesTo[0] }
        else
          if std.length(definition.appliesTo.allExcept) > 0 then
            { type: [{ ne: '' }, { nre: std.join('|', definition.appliesTo.allExcept) }] }
          else
            { type: { ne: '' } }
      ),

    getFormatConfig()::
      local definition = self;
      local selectorHash = definition.getTypeFilter();
      local staticLabels = definition.staticLabels;

      // Remove any statically defined labels from the selectors, if they are defined
      local selectorWithoutStaticLabels = selectors.without(selectorHash, staticLabels);

      local aggregationLabels = if definition.topk == null then
        environmentLabels
      else
        environmentLabels + definition.resourceLabels;

      local aggregationLabelsWithoutStaticLabels = std.filter(function(label) !std.objectHas(staticLabels, label), aggregationLabels);

      definition.queryFormatConfig {
        selector: selectors.serializeHash(selectorWithoutStaticLabels),
        aggregationLabels: aggregations.serialize(aggregationLabelsWithoutStaticLabels),
      },

    getTopkQuery()::
      local definition = self;
      local formatConfig = definition.getFormatConfig();
      local preaggregationQuery = definition.query % formatConfig;

      |||
        topk by(%(aggregationLabels)s) (%(topk)d,
          %(preaggregationQuery)s
        )
      ||| % formatConfig {
        topk: definition.topk,
        preaggregationQuery: strings.indent(preaggregationQuery, 2),
      },

    getTotalQuery()::
      local definition = self;
      local formatConfig = definition.getFormatConfig();
      definition.query % formatConfig,

    getLegendFormat()::
      if std.length(definition.resourceLabels) > 0 then
        std.join(' ', std.map(function(f) '{{ ' + f + ' }}', definition.resourceLabels))
      else
        '{{ type }}',

    getStaticLabels()::
      self.staticLabels,

    getRecordingRuleDefinitions(componentName)::
      local definition = self;

      if definition.topk == null then
        [{
          record: 'gitlab_component_utilization:rate_1h',
          labels: {
            component: componentName,
          } + definition.getStaticLabels(),
          expr: definition.getTotalQuery(),
        }]
      else
        [{
          record: 'gitlab_component_utilization:topk:rate_1h',
          labels: {
            component: componentName,
          } + definition.getStaticLabels(),
          expr: definition.getTopkQuery(),
        }],

    // Returns a boolean to indicate whether this saturation point applies to
    // a given service
    appliesToService(type)::
      serviceApplicator(type),

    // When a dashboard for this alert is opened without a type,
    // what should the default be?
    // For allowLists: always use the first item
    // For blockLists: use the default or web
    getDefaultGrafanaType()::
      if std.isArray(definition.appliesTo) then
        definition.appliesTo[0]
      else
        if std.objectHas(definition.appliesTo, 'default') then
          definition.appliesTo.default
        else
          'web',
  };

{
  utilizationMetric:: utilizationMetric,
}
