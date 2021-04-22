local services = import './services/all.jsonnet';
local prometheusServiceGroupGenerator = import 'prometheus-service-group-generator.libsonnet';

local outputPromYaml(groups) =
  std.manifestYamlDoc({
    groups: groups,
  });

local featureCategoryFileForService(service) =
  if service.hasFeatureCatogorySLIs() then
    {
      ['feature-category-metrics-%s.yml' % [service.type]]:
        outputPromYaml(
          prometheusServiceGroupGenerator.featureCategoryRecordingRuleGroupsForService(service)
        ),
    }
  else {};

local filesForService(service) =
  {
    ['key-metrics-%s.yml' % [service.type]]:
      outputPromYaml(
        prometheusServiceGroupGenerator.recordingRuleGroupsForService(service)
      ),
  } + featureCategoryFileForService(service);

/**
 * The source SLI recording rules are each kept in their own files, generated from this
 */

std.foldl(function(memo, service) memo + filesForService(service), services, {})
