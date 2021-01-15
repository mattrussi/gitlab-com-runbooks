{
  componentNodeApdexRatioRuleSet(suffix)::
    {
      generateRecordingRules()::
        local format = {
          suffix: suffix,
        };

        [{
          record: 'gitlab_component_node_apdex:weight:score%(suffix)s' % format,
          expr: |||
            sum by (env,environment,tier,type,stage,shard,fqdn,component) (
              (gitlab_component_node_apdex:weight:score%(suffix)s{monitor!="global"} >= 0)
            )
          ||| % format,
        }, {
          record: 'gitlab_component_node_apdex:ratio%(suffix)s' % format,
          expr: |||
            sum by (env,environment,tier,type,stage,shard,fqdn,component) (
              (
                (gitlab_component_node_apdex:ratio%(suffix)s{monitor!="global"} >= 0)
                *
                (gitlab_component_node_apdex:weight:score%(suffix)s{monitor!="global"} >= 0)
              )
            )
            /
            sum by (env,environment,tier,type,stage,shard,fqdn,component) (
              (gitlab_component_node_apdex:weight:score%(suffix)s{monitor!="global"} >= 0)
            )
          ||| % format,
        }],
    },

}
