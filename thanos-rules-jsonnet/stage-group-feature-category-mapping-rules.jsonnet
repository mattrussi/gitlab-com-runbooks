local mappingGroups = import 'recording-rules/feature-category-mapping.libsonnet';

// This mapping is recorded globally and applicable to all environments.
// No need to separate this by env

local presentThanosRuleGroup(ruleGroup) = ruleGroup { partial_response_strategy: 'warn' };

{
  'stage-group-feature-category-mapping-rules.yml': std.manifestYamlDoc({
    groups: std.map(presentThanosRuleGroup, mappingGroups),
  }),
}
