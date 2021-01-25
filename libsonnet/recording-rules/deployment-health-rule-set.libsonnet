local aggregationSets = import 'aggregation-sets.libsonnet';
local mwmbrExpression = import 'mwmbr/expression.libsonnet';

{
  deploymentHealthRuleSet()::
    [{
      record: 'gitlab_deployment_health:service:errors',
      expr: mwmbrExpression.errorHealthExpression(
        aggregationSet=aggregationSets.serviceAggregatedSLIs,
        metricSelectorHash={},
        thresholdSLOMetricName='slo:max:deployment:gitlab_service_errors:ratio',
        thresholdSLOMetricAggregationLabels=['type', 'tier'],
      ),
    }, {
      record: 'gitlab_deployment_health:service:apdex',
      expr: mwmbrExpression.apdexHealthExpression(
        aggregationSet=aggregationSets.serviceAggregatedSLIs,
        metricSelectorHash={},
        thresholdSLOMetricName='slo:min:deployment:gitlab_service_apdex:ratio',
        thresholdSLOMetricAggregationLabels=['type', 'tier'],
      ),
    }, {
      record: 'gitlab_deployment_health:service',
      expr: |||
        min without (sli_type) (
          label_replace(gitlab_deployment_health:service:apdex{monitor="global"}, "sli_type", "apdex", "", "")
          or
          label_replace(gitlab_deployment_health:service:errors{monitor="global"}, "sli_type", "errors", "", "")
        )
      |||,
    }, {
      record: 'gitlab_deployment_health:stage',
      expr: |||
        min by (environment, env, stage) (
          gitlab_deployment_health:service{monitor="global"}
        )
      |||,
    }],
}
