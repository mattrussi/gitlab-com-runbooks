local multiburnExpression = import 'mwmbr/expression.libsonnet';
local serviceLevelIndicatorDefinition = import 'service_level_indicator_definition.libsonnet';

// For now we assume that services are provisioned on vms and not kubernetes
local provisioningDefaults = { vms: true, kubernetes: false };
local serviceDefaults = {
  serviceIsStageless: false,  // Set to true for services that don't use stage labels
  autogenerateRecordingRules: true,
  disableOpsRatePrediction: false,
  nodeLevelMonitoring: false,  // By default we do not use node-level monitoring
  kubeResources: {},
  regional: false,  // By default we don't support regional monitoring for services,
  alertWindows: multiburnExpression.defaultWindows,
  excludedMaturityCriteria: [],
};

// Convience method, will wrap a raw definition in a serviceLevelIndicatorDefinition if needed
local prepareComponent(definition) =
  if std.objectHasAll(definition, 'initServiceLevelIndicatorWithName') then
    // Already prepared
    definition
  else
    // Wrap class as a component definition
    serviceLevelIndicatorDefinition.serviceLevelIndicatorDefinition(definition);

local validateAndApplyServiceDefaults(service) =
  local serviceWithProvisioningDefaults = serviceDefaults + ({ provisioning: provisioningDefaults } + service);
  local sliInheritedDefaults =
    { regional: serviceWithProvisioningDefaults.regional }
    +
    (
      // When stage labels are disabled, we default all SLI recording rules
      // to the main stage
      if serviceWithProvisioningDefaults.serviceIsStageless then
        { staticLabels+: { stage: 'main' } }
      else
        {}
    );

  // If this service is provisioned on kubernetes we should include a kubernetes deployment map
  if serviceWithProvisioningDefaults.provisioning.kubernetes == (serviceWithProvisioningDefaults.kubeResources != {}) then
    serviceWithProvisioningDefaults {
      serviceLevelIndicators: {
        [sliName]: prepareComponent(service.serviceLevelIndicators[sliName]).initServiceLevelIndicatorWithName(sliName, sliInheritedDefaults)
        for sliName in std.objectFields(service.serviceLevelIndicators)
      },
    }
  else
    // Service definition has a mismatch between provisioning.kubernetes and kubeResources
    std.assertEqual(false, { __message__: 'Mismatching kubernetes config for service ' + service.type });

local serviceDefinition(service) =
  // Private functions
  local private = {
    serviceHasComponentWith(keymetricName)::
      std.foldl(
        function(memo, sliName) memo || std.objectHas(service.serviceLevelIndicators[sliName], keymetricName),
        std.objectFields(service.serviceLevelIndicators),
        false
      ),
    serviceHasComponentWithFeatureCategory()::
      std.foldl(
        function(memo, sliName) memo || service.serviceLevelIndicators[sliName].hasFeatureCategory(),
        std.objectFields(service.serviceLevelIndicators),
        false
      ),
  };

  service {
    hasApdex():: private.serviceHasComponentWith('apdex'),
    hasRequestRate():: true,  // requestRate is mandatory
    hasErrorRate():: private.serviceHasComponentWith('errorRate'),
    hasFeatureCatogorySLIs():: private.serviceHasComponentWithFeatureCategory(),

    getProvisioning()::
      service.provisioning,

    // Returns an array of serviceLevelIndicators for this service
    listServiceLevelIndicators()::
      [
        service.serviceLevelIndicators[sliName]
        for sliName in std.objectFields(service.serviceLevelIndicators)
      ],
  };

{
  serviceDefinition(service)::
    serviceDefinition(validateAndApplyServiceDefaults(service)),
}
