local services = import './services/all.jsonnet';
local serviceMap = std.foldl(function(running, service) running { [service.type]: service }, services, {});
local saturationResource = import './servicemetrics/saturation-resources.libsonnet';

local serviceApplicableSaturationTypes(service)
      = saturationResource.listApplicableServicesFor(service.type);

{
  services:: services,
  getService(serviceType)::
    local service = serviceMap[serviceType];
    service {
      applicableSaturationTypes():: serviceApplicableSaturationTypes(service),
    },
}
