local alerts = import 'alerts/alerts.libsonnet';
local serviceAlertsGenerator = import 'slo-alerts/service-alerts-generator.libsonnet';

local alertDescriptors(aggregationSets, minimumSamplesForMonitoring, minimumSamplesForTrafficCessation) = [{
  predicate: function(service, sli) !sli.shardLevelMonitoring,
  alertSuffix: '',
  alertTitleTemplate: 'The %(sliName)s SLI of the %(serviceType)s service (`{{ $labels.stage }}` stage)',
  alertExtraDetail: null,
  aggregationSet: aggregationSets.componentSLIs,
  minimumSamplesForMonitoring: minimumSamplesForMonitoring,
  alertForDuration: null,  // Use default for window...
  trafficCessationSelector: null,
  minimumSamplesForTrafficCessation: minimumSamplesForTrafficCessation,
}, {
  predicate: function(service, sli) sli.shardLevelMonitoring,
  alertSuffix: 'SingleShard',
  alertTitleTemplate: 'The %(sliName)s SLI of the %(serviceType)s service on shard `{{ $labels.shard }}`',
  alertExtraDetail: 'Since the `{{ $labels.type }}` service is not fully redundant, SLI violations on a single shard may represent a user-impacting service degradation.',
  aggregationSet: aggregationSets.shardComponentSLIs,
  minimumSamplesForMonitoring: minimumSamplesForMonitoring,
  alertForDuration: null,
  trafficCessationSelector: {},
  minimumSamplesForTrafficCessation: minimumSamplesForTrafficCessation,
}];

local annotations(description='') = {
  runbook: "docs/hosted-runners/README.md",
  description: description
};

local customRules() =
  local rules = [
    {
      alert: 'HostedRunnersServiceRunnerManagerDownSingleShard',
      expr:'gitlab_component_shard_ops:rate_5m{component="api_requests",type="hosted-runners"} == 0',
      'for': '5m',
      labels: {
        severity: 's1',
        alert_type: 'cause',
      },
      annotations: annotations(
        description='The runner manager in HostedRunnersService has disconnected for a single shard. This may impact job scheduling for that shard.',
      ),
    }
  ];

  {
    rules+: alerts.processAlertRules(rules),
  };


local alertsForServices(config) =
    local metricsConfig = config.gitlabMetricsConfig;
    local minimumSamplesForMonitoring = config.minimumSamplesForMonitoring;
    local minimumSamplesForTrafficCessation = config.minimumSamplesForTrafficCessation;

    std.foldl(
      function(memo, service)
        memo + serviceAlertsGenerator(
        service,
        alertDescriptors(
          metricsConfig.aggregationSets,
          minimumSamplesForMonitoring,
          minimumSamplesForTrafficCessation
        ),
        customRules()
      ),
      metricsConfig.monitoredServices,
      []
    );

alertsForServices
