local selectors = import 'promql/selectors.libsonnet';
local strings = import 'utils/strings.libsonnet';

local environmentLabels = ['environment', 'tier', 'type', 'stage'];

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
    std.isString(definition.grafana_dashboard_uid) &&
    std.isArray(definition.resourceLabels) &&
    std.isString(definition.query);

  // Apply defaults
  if validated then
    {
      staticLabels: {},
      queryFormatConfig: {},
      topk: 10,
    } + definition + {
    }
  else
    std.assertEqual(definition, { __assert__: 'Resource definition is invalid' });

local utilizationMetric = function(options)
  local definition = validateAndApplyDefaults(options);
  local serviceApplicator = getServiceApplicator(definition.appliesTo);

  definition {
    getQuery(selectorHash, rangeInterval, maxAggregationLabels=[])::
      local staticLabels = definition.staticLabels;
      local queryAggregationLabels = environmentLabels + self.resourceLabels;
      local allMaxAggregationLabels = environmentLabels + maxAggregationLabels;
      local queryAggregationLabelsExcludingStaticLabels = std.filter(function(label) !std.objectHas(staticLabels, label), queryAggregationLabels);
      local maxAggregationLabelsExcludingStaticLabels = std.filter(function(label) !std.objectHas(staticLabels, label), allMaxAggregationLabels);
      local queryFormatConfig = self.queryFormatConfig;

      // Remove any statically defined labels from the selectors, if they are defined
      local selectorWithoutStaticLabels = if staticLabels == {} then selectorHash else selectors.without(selectorHash, staticLabels);

      local preaggregation = self.query % queryFormatConfig {
        // rangeInterval: rangeInterval,
        selector: selectors.serializeHash(selectorWithoutStaticLabels),
        aggregationLabels: std.join(', ', queryAggregationLabelsExcludingStaticLabels),
      };

      |||
        topk by(%(maxAggregationLabels)s) (%(topk)d,
          %(quantileOverTimeQuery)s
        )
      ||| % {
        topk: definition.topk,
        quantileOverTimeQuery: strings.indent(preaggregation, 2),
        maxAggregationLabels: std.join(', ', maxAggregationLabelsExcludingStaticLabels),
      },

    getLegendFormat()::
      if std.length(definition.resourceLabels) > 0 then
        std.join(' ', std.map(function(f) '{{ ' + f + ' }}', definition.resourceLabels))
      else
        '{{ type }}',

    getStaticLabels()::
      ({ staticLabels: {} } + definition).staticLabels,

    // This signifies the minimum period over which this resource is
    // evaluated. Defaults to 1m, which is the legacy value
    getBurnRatePeriod()::
      ({ burnRatePeriod: '1m' } + self).burnRatePeriod,

    getRecordingRuleDefinition(componentName)::
      local definition = self;

      local typeFilter =
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
        );

      local query = definition.getQuery(typeFilter, definition.getBurnRatePeriod());

      {
        record: 'gitlab_component_saturation:ratio',
        labels: {
          component: componentName,
        } + definition.getStaticLabels(),
        expr: query,
      },

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
  utilizationMetric:: utilizationMetric
}
