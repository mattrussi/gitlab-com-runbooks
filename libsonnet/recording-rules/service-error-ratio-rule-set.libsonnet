{
  // serviceErrorRatioRuleSet generates rules at different burn rates for
  // aggregating component level error ratios up to the service level.
  // This is calculated as the total number of errors handled by the service
  // as a ratio of total requests to the service.
  serviceErrorRatioRuleSet(suffix)::
    {
      generateRecordingRules()::
        local format = { suffix: suffix };

        [{
          record: 'gitlab_service_errors:rate%(suffix)s' % format,
          expr: |||
            sum by (env,environment,tier,type,stage) (
              gitlab_component_errors:rate%(suffix)s{monitor!="global"} >= 0 and on(component, type) (gitlab_component_service:mapping{monitor="global", service_aggregation="yes"})
            )
          ||| % format,
        }, {
          record: 'gitlab_service_ops:rate%(suffix)s' % format,
          expr: |||
            sum by (env,environment,tier,type,stage) (
              gitlab_component_ops:rate%(suffix)s{monitor!="global"} >= 0 and on(component, type) (gitlab_component_service:mapping{monitor="global", service_aggregation="yes"})
            )
          ||| % format,
        }, {
          // Uses the `monitor=global` globally aggregated values from the previous two
          // recording rules to calculate a ratio
          record: 'gitlab_service_errors:ratio%(suffix)s' % format,
          expr: |||
            gitlab_service_errors:rate%(suffix)s{monitor="global"}
            /
            gitlab_service_ops:rate%(suffix)s{monitor="global"}
          ||| % format,
        }],
    },
}
