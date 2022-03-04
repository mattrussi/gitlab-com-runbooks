local aggregationSets = import 'aggregation-sets.libsonnet';
local alerts = import 'alerts/alerts.libsonnet';
local selectors = import 'promql/selectors.libsonnet';
local serviceCatalog = import 'service-catalog/service-catalog.libsonnet';
local metricsCatalog = import 'servicemetrics/metrics-catalog.libsonnet';
local serviceLevelAlerts = import 'slo-alerts/service-level-alerts.libsonnet';
local sloAlertAnnotations = import 'slo-alerts/slo-alert-annotations.libsonnet';
local strings = import 'utils/strings.libsonnet';

// Minimum operation rate thresholds:
// This is to avoid low-volume, noisy alerts.
// See docs/metrics-catalog/service-level-monitoring.md for more details
// of how minimumSamplesForMonitoring works
local minimumSamplesForMonitoring = 3600;
local minimumSamplesForNodeMonitoring = 1200;

// Most MWMBR alerts use a 2m period
// Initially for this alert, use a long period to ensure that
// it's not too noisy.
// Consider bringing this down to 2m after 1 Sep 2020
local nodeAlertWaitPeriod = '10m';

local labelsForSLIAlert(sli) =
  local labels = {
    user_impacting: if sli.userImpacting then 'yes' else 'no',
  };

  local team = if sli.team != null then serviceCatalog.getTeam(sli.team) else null;
  local featureCategoryLabels = if sli.hasStaticFeatureCategory() then
    sli.staticFeatureCategoryLabels()
  else if sli.hasFeatureCategoryFromSourceMetrics() then
    // This indicates that there might be multiple
    // feature categories contributing to the component
    // that is alerting. This is not nescessarily
    // caused by a single feature category
    { feature_category: 'in_source_metrics' }
  else if !sli.hasFeatureCategory() then
    { feature_category: 'not_owned' };

  labels + featureCategoryLabels + (
    if team != null && team.issue_tracker != null then
      { incident_project: team.issue_tracker }
    else
      {}
  ) + (
    /**
     * When team.send_slo_alerts_to_team_slack_channel is configured in the service catalog
     * alerts will be sent to slack team alert channels in addition to the
     * usual locations
     */
    if team != null && team.send_slo_alerts_to_team_slack_channel then
      { team: sli.team }
    else
      {}
  );

local aggregationSetSLOAlertDescriptors = [{
  predicate: function(service) true,
  alertSuffix: '',
  alertTitleTemplate: 'The %(sliName)s SLI of the %(serviceType)s service (`{{ $labels.stage }}` stage)',
  alertExtraDetail: null,
  aggregationSet: aggregationSets.componentSLIs,
  minimumSamplesForMonitoring: minimumSamplesForMonitoring,
  alertForDuration: null,  // Use default for window...
  trafficCessationSelector: { stage: 'main' },  // Don't alert on cny stage traffic cessation for now
}, {
  predicate: function(service) service.nodeLevelMonitoring,
  alertSuffix: 'SingleNode',
  alertTitleTemplate: 'The %(sliName)s SLI of the %(serviceType)s service on node `{{ $labels.fqdn }}`',
  alertExtraDetail: 'Since the `{{ $labels.type }}` service is not fully redundant, SLI violations on a single node may represent a user-impacting service degradation.',
  aggregationSet: aggregationSets.nodeComponentSLIs,
  minimumSamplesForMonitoring: minimumSamplesForNodeMonitoring,  // Note: lower minimum sample rate for node-level monitoring
  alertForDuration: nodeAlertWaitPeriod,
  trafficCessationSelector: {},
}, {
  predicate: function(service) service.regional,
  alertSuffix: 'Regional',
  alertTitleTemplate: 'The %(sliName)s SLI of the %(serviceType)s service in region `{{ $labels.region }}`',
  alertExtraDetail: 'Note that this alert is specific to the `{{ $labels.region }}` region.',
  aggregationSet: aggregationSets.regionalComponentSLIs,
  minimumSamplesForMonitoring: minimumSamplesForMonitoring,
  alertForDuration: null,  // Use default for window...
  trafficCessationSelector: { stage: 'main' },  // Don't alert on cny stage traffic cessation for now
}];

local apdexAlertForSLIForAlertDescriptor(service, sli, alertDescriptor) =
  local apdexScoreSLO = sli.monitoringThresholds.apdexScore;
  local formatConfig = {
    sliName: sli.name,
    serviceType: service.type,
  };

  serviceLevelAlerts.apdexAlertsForSLI(
    alertName=serviceLevelAlerts.nameSLOViolationAlert(service.type, sli.name, 'ApdexSLOViolation' + alertDescriptor.alertSuffix),
    alertTitle=(alertDescriptor.alertTitleTemplate + ' has an apdex violating SLO') % formatConfig,
    alertDescriptionLines=[sli.description] + if alertDescriptor.alertExtraDetail != null then [alertDescriptor.alertExtraDetail] else [],
    serviceType=service.type,
    severity=sli.severity,
    thresholdSLOValue=apdexScoreSLO,
    aggregationSet=alertDescriptor.aggregationSet,
    windows=service.alertWindows,
    metricSelectorHash={ type: service.type, component: sli.name },
    minimumSamplesForMonitoring=alertDescriptor.minimumSamplesForMonitoring,
    alertForDuration=alertDescriptor.alertForDuration,
    extraLabels=labelsForSLIAlert(sli),
    extraAnnotations=sloAlertAnnotations(service.type, sli, alertDescriptor.aggregationSet, 'apdex')
  );


local errorAlertForSLIForAlertDescriptor(service, sli, alertDescriptor) =
  local errorRateSLO = sli.monitoringThresholds.errorRatio;
  local formatConfig = {
    sliName: sli.name,
    serviceType: service.type,
  };

  serviceLevelAlerts.errorAlertsForSLI(
    alertName=serviceLevelAlerts.nameSLOViolationAlert(service.type, sli.name, 'ErrorSLOViolation' + alertDescriptor.alertSuffix),
    alertTitle=(alertDescriptor.alertTitleTemplate + ' has an error rate violating SLO') % formatConfig,
    alertDescriptionLines=[sli.description] + if alertDescriptor.alertExtraDetail != null then [alertDescriptor.alertExtraDetail] else [],
    serviceType=service.type,
    severity=sli.severity,
    thresholdSLOValue=errorRateSLO,
    aggregationSet=alertDescriptor.aggregationSet,
    windows=service.alertWindows,
    metricSelectorHash={ type: service.type, component: sli.name },
    minimumSamplesForMonitoring=alertDescriptor.minimumSamplesForMonitoring,
    extraLabels=labelsForSLIAlert(sli),
    alertForDuration=alertDescriptor.alertForDuration,
    extraAnnotations=sloAlertAnnotations(service.type, sli, alertDescriptor.aggregationSet, 'error'),
  );

// Generates an apdex alert for an SLI
local apdexAlertForSLI(service, sli) =
  std.flatMap(
    function(descriptor)
      if descriptor.predicate(service) then
        apdexAlertForSLIForAlertDescriptor(service, sli, descriptor)
      else
        [],
    aggregationSetSLOAlertDescriptors
  );

// Generates an error rate alert for an SLI
local errorRateAlertsForSLI(service, sli) =
  std.flatMap(
    function(descriptor)
      if descriptor.predicate(service) then
        errorAlertForSLIForAlertDescriptor(service, sli, descriptor)
      else
        [],
    aggregationSetSLOAlertDescriptors
  );

local trafficCessationAlertForSLIForAlertDescriptor(service, sli, descriptor) =
  local aggregationSet = descriptor.aggregationSet;
  local opsRate30mMetric = aggregationSet.getOpsRateMetricForBurnRate('30m', required=false);
  local opsRate5mMetric = aggregationSet.getOpsRateMetricForBurnRate('5m', required=false);
  local aggregationSetSelector = aggregationSet.selector;

  local selector = {
    type: service.type,
    component: sli.name,
  } + aggregationSetSelector + descriptor.trafficCessationSelector;

  local sliDescription = strings.chomp(sli.description);

  local formatConfig = {
    sliName: sli.name,
    serviceType: service.type,
    opsRate5mMetric: opsRate5mMetric,
    opsRate30mMetric: opsRate30mMetric,
    selector: selectors.serializeHash(selector),
  };

  (if opsRate30mMetric != null then
     [{
       alert: serviceLevelAlerts.nameSLOViolationAlert(service.type, sli.name, 'TrafficCessation' + descriptor.alertSuffix),
       expr: |||
         %(opsRate30mMetric)s{%(selector)s} == 0
       ||| % formatConfig,
       'for': '5m',
       labels:
         serviceLevelAlerts.labelsForAlert(sli.severity, aggregationSets.componentSLIs, 'ops', 'traffic_cessation', windowDuration=null)
         +
         labelsForSLIAlert(sli),
       annotations:
         serviceLevelAlerts.commonAnnotations(service.type, aggregationSets.componentSLIs, 'ops') +
         sloAlertAnnotations(service.type, sli, aggregationSets.componentSLIs, 'ops') +
         {
           title: (descriptor.alertTitleTemplate + ' has not received any traffic in the past 30 minutes') % formatConfig,
           description: strings.markdownParagraphs(
             [
               sliDescription,
               'This alert signifies that the SLI is reporting a cessation of traffic; the signal is present, but is zero.',
             ] +
             if descriptor.alertExtraDetail != null then [descriptor.alertExtraDetail] else []
           ),
           // grafana_variables: 'environment,stage',
         },
     }] else [])
  +
  (if opsRate5mMetric != null then
     [{
       alert: serviceLevelAlerts.nameSLOViolationAlert(service.type, sli.name, 'TrafficAbsent' + descriptor.alertSuffix),
       expr: |||
         %(opsRate5mMetric)s{%(selector)s} offset 1h
         unless
         %(opsRate5mMetric)s{%(selector)s}
       ||| % formatConfig,
       'for': '30m',
       labels:
         serviceLevelAlerts.labelsForAlert(sli.severity, aggregationSets.componentSLIs, 'ops', 'traffic_cessation', windowDuration=null)
         +
         labelsForSLIAlert(sli),
       annotations:
         serviceLevelAlerts.commonAnnotations(service.type, aggregationSets.componentSLIs, 'ops') +
         sloAlertAnnotations(service.type, sli, aggregationSets.componentSLIs, 'ops') +

         {
           title: (descriptor.alertTitleTemplate + ' has not reported any traffic in the past 30 minutes') % formatConfig,
           description: strings.markdownParagraphs(
             [
               sliDescription,
               'This alert signifies that the SLI was previously reporting traffic, but is no longer - the signal is absent.',
               'This could be caused by a change to the metrics used in the SLI, or by the service not receiving traffic.',
             ] +
             if descriptor.alertExtraDetail != null then [descriptor.alertExtraDetail] else []
           ),
         },
     }] else []);

local trafficCessationAlertsForSLI(service, sli) =
  std.flatMap(
    function(descriptor)
      if descriptor.predicate(service) then
        trafficCessationAlertForSLIForAlertDescriptor(service, sli, descriptor)
      else
        [],
    aggregationSetSLOAlertDescriptors
  );


local alertsForService(service) =
  local slis = service.listServiceLevelIndicators();

  local rules = std.flatMap(
    function(sli)
      (
        if sli.hasApdexSLO() && sli.hasApdex() then
          apdexAlertForSLI(service, sli)
        else
          []
      )
      +
      (
        if sli.hasErrorRateSLO() && sli.hasErrorRate() then
          errorRateAlertsForSLI(service, sli)
        else
          []
      )
      +
      (
        if !sli.ignoreTrafficCessation then  // Alert on a zero RPS operation rate for this SLI
          trafficCessationAlertsForSLI(service, sli)
        else
          []
      ),
    slis
  );
  alerts.processAlertRules(rules);

local groupsForService(service) = {
  groups: [{
    name: 'Service Component Alerts: %s' % [service.type],
    partial_response_strategy: 'warn',
    interval: '1m',
    rules: alertsForService(service),
  }],
};

std.foldl(
  function(docs, service)
    docs {
      ['service-level-alerts-%s.yml' % [service.type]]: std.manifestYamlDoc(groupsForService(service)),
    },
  metricsCatalog.services,
  {},
)
