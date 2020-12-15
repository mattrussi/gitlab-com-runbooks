local services = import './services/all.jsonnet';
local prometheusServiceGroupGenerator = import 'prometheus-service-group-generator.libsonnet';

local outputPromYaml(groups) =
  std.manifestYamlDoc({
    groups: groups,
  });

// Select all services with `autogenerateRecordingRules` (default on)
local selectedServices = std.filter(function(service) service.autogenerateRecordingRules, services);

/**
 * The source SLI recording rules are each kept in their own files, generated from this
 */
{
  ['key-metrics-%s.yml' % [service.type]]:
    outputPromYaml(
      prometheusServiceGroupGenerator.recordingRuleGroupsForService(service)
    )
  for service in services
}
