local subnetSizes = import 'recording-rules/subnet-sizes.libsonnet';

local presentThanosRuleGroup(ruleGroup) = ruleGroup { partial_response_strategy: 'warn' };

{
  // We're only recording this for 'gprd' with a static label. No need to separate
  // across environments
  'subnet-sizes-gprd.yml': std.manifestYamlDoc({ groups: std.map(presentThanosRuleGroup, subnetSizes.gprd) }),
}
