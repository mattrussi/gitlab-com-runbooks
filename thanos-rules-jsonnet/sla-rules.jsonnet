local slas = import './lib/slas.libsonnet';
local serviceCatalog = import 'service_catalog.libsonnet';

local keyServices = serviceCatalog.findServices(function(service)
  std.objectHas(service.business.SLA, 'overall_sla_weighting') && service.business.SLA.overall_sla_weighting > 0);

local keyServiceWeights = std.foldl(
  function(memo, item) memo {
    [item.name]: item.business.SLA.overall_sla_weighting,
  }, keyServices, {}
);

local getWeightedQuery(template) =
  local items = [
    template % {
      type: type,
      weight: keyServiceWeights[type],
    }
    for type in std.objectFields(keyServiceWeights)
  ];

  std.join('\n  or\n  ', items);

local rules = {
  groups: [{
    name: 'SLA weight calculations',
    partial_response_strategy: 'warn',
    interval: '1m',
    rules:
      slas.internal.getRecordingRules() +
      slas.external.getRecordingRules(),
  }],
};

{
  'sla-rules.yml': std.manifestYamlDoc(rules),
}
