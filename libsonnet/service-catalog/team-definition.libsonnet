local metricsConfig = import 'gitlab-metrics-config.libsonnet';
local allServices = metricsConfig.monitoredServices;
local stageGroupMapping = metricsConfig.stageGroupMapping;
local miscUtils = import 'utils/misc.libsonnet';
local validator = import 'utils/validator.libsonnet';

local serviceComponents = std.set(
  std.flatMap(
    function(o) std.objectFields(o.serviceLevelIndicators),
    allServices
  )
);

local ignoredComponentsValidator = validator.validator(
  function(teamIgnoredComponents)
    std.prune(teamIgnoredComponents) == null ||
    miscUtils.all(
      function(value) std.member(serviceComponents, value),
      teamIgnoredComponents
    ),
  'only components %s are supported' % [std.join(', ', serviceComponents)]
);

local productStageGroupValidator = validator.validator(
  function(stageGroup)
    std.prune(stageGroup) == null || std.objectHas(stageGroupMapping, stageGroup),
  'unknown stage group'
);

local teamValidator = validator.new({
  name: validator.string,
  send_slo_alerts_to_team_slack_channel: validator.boolean,
  ignored_components: ignoredComponentsValidator,
  product_stage_group: productStageGroupValidator,
});

local teamDefaults = {
  issue_tracker: null,
  send_slo_alerts_to_team_slack_channel: false,
  ignored_components: [],
  product_stage_group: null,
};

{
  defaults: teamDefaults,

  // only for tests
  _validator: teamValidator,
  _serviceComponents: serviceComponents,
}
