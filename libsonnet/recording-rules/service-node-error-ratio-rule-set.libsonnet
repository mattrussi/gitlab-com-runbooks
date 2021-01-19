{
  // The serviceNodeErrorRatio ruleset will generate recording rules for a particular burn rate
  // to roll up nodeLevelMonitoring to the service level, providing insights into nodes
  // at a service level.
  //
  // Note: Only gitaly currently uses nodeLevelMonitoring.
  serviceNodeErrorRatioRuleSet(suffix)::
    {
      generateRecordingRules()::
        local format = {
          suffix: suffix,
        };

        [{
          record: 'gitlab_service_node_errors:rate%(suffix)s' % format,
          expr: |||
            sum by (env,environment,tier,type,stage,shard,fqdn) (
              gitlab_component_node_errors:rate%(suffix)s{monitor!="global"} >= 0
            )
          ||| % format,
        }, {
          record: 'gitlab_service_node_ops:rate%(suffix)s' % format,
          expr: |||
            sum by (env,environment,tier,type,stage,shard,fqdn) (
              gitlab_component_node_ops:rate%(suffix)s{monitor!="global"} >= 0 and on(component, type) (gitlab_component_service:mapping{monitor="global", aggregate_rps="yes"})
            )
          ||| % format,
        }, {
          // Uses the `monitor=global` globally aggregated values from the previous two
          // recording rules to calculate a ratio
          record: 'gitlab_service_node_errors:ratio%(suffix)s' % format,
          expr: |||
            gitlab_service_node_errors:rate%(suffix)s{monitor="global"}
            /
            gitlab_service_node_ops:rate%(suffix)s{monitor="global"}
          ||| % format,
        }],
    },

}
