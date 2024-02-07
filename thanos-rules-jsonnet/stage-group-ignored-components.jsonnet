local ignoredComponentRuleGroups = import 'recording-rules/stage-group-ignored-components.libsonnet';

local outputPromYaml(groups) =
  std.manifestYamlDoc({
    groups: groups,
  });

// See https://thanos.io/v0.34/components/query.md/#partial-response
local presentThanosRuleGroup(ruleGroup) = ruleGroup { partial_response_strategy: 'warn' };

// The ignored components are the same for a group across environments.
// No need to separate this by environment
{
  'stage-group-ignored-components.yml': outputPromYaml(std.map(presentThanosRuleGroup, ignoredComponentRuleGroups)),
}
