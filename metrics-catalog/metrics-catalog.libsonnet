local services = import './services/all.jsonnet';
local serviceMap = std.foldl(function(running, service) running { [service.type]: service }, services, {});
local saturationResource = import './saturation-resources.libsonnet';

local serviceApplicableSaturationTypes(service)
      = saturationResource.listApplicableServicesFor(service.type);

local listServiceLevelIndicatorsForFeatureCategories(featureCategories) =
  local fcSet = std.set(featureCategories);
  local allSLIs = std.flatMap(function(service) std.trace(""+service, service.listServiceLevelIndicators()), services);
  std.filter(function(sli) std.setMember(sli.featureCategory, fcSet), allSLIs);

{
  services:: services,

  // Given a list of feature categories, will return all SLIs associated
  // with these feature categories
  listServiceLevelIndicatorsForFeatureCategories(featureCategories)::
    listServiceLevelIndicatorsForFeatureCategories(featureCategories),

  getService(serviceType)::
    local service = serviceMap[serviceType];
    service {
      applicableSaturationTypes():: serviceApplicableSaturationTypes(service),
    },
}
