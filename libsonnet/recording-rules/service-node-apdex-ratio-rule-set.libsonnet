{
  // The serviceNodeApdexRatio ruleset will generate recording rules for a particular burn rate
  // to roll up nodeLevelMonitoring to the service level, providing insights into nodes
  // at a service level.
  //
  // Note: Only gitaly currently uses nodeLevelMonitoring.
  serviceNodeApdexRatioRuleSet(suffix)::
    {
      generateRecordingRules()::
        local format = {
          suffix: suffix,
        };

        [{
          record: 'gitlab_service_node_apdex:ratio%(suffix)s' % format,
          expr: |||
            sum by (env, environment, tier, type, stage, shard, fqdn) (
              (
                (gitlab_component_node_apdex:ratio%(suffix)s{monitor!="global"} >= 0)
                *
                (gitlab_component_node_apdex:weight:score%(suffix)s{monitor!="global"} >= 0)
              )
            )
            /
            sum by (env, environment, tier, type, stage, shard, fqdn) (
              (gitlab_component_node_apdex:weight:score%(suffix)s{monitor!="global"} >= 0)
            )
          ||| % format,
        }],
    },

}
