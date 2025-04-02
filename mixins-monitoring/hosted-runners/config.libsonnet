local gitlabMetricsConfig = import 'gitlab-metrics-config.libsonnet';
local alertsForServices = import 'lib/alerts-generator.libsonnet';
local aggregationRulesForServices = import 'lib/rules-generator.libsonnet';
local saturationResource = import 'lib/saturation.libsonnet';
local hostedRunnerserviceDefinition = import 'lib/service.libsonnet';
local templates = import 'lib/templates.libsonnet';

{
  _config+:: {
    gitlabMetricsConfig+:: gitlabMetricsConfig,

    prometheusDatasource: 'Global',

    // The rate interval for dashboard.
    rateInterval: '5m',

    // The dashboard name used when building dashboards.
    dashboardName: 'Hosted Runners',

    // Tags for dashboards.
    dashboardTags: ['hosted-runners', 'dedicated'],

    // Query selector based on the hosted runner name
    runnerNameSelector: 'shard=~"$shard"',

    // Query selector based on the hosted runner job combine with runner name
    runnerJobSelector: 'job="hosted-runners-prometheus-agent"',

    fluentdPluginSelector: 'shard=~"$shard", plugin=~"$plugin"',

    replicationSelector: 'rule_id="replication-rule-hosted-runner"',

    minimumSamplesForMonitoring: 50,

    minimumSamplesForTrafficCessation: 300,

    templates:: templates,
  },

  prometheusRulesGroups+:: aggregationRulesForServices(self._config),

  prometheusAlertsGroups+:: alertsForServices(self._config),

}
