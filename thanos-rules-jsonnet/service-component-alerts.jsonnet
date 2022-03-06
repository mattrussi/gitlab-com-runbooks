local aggregationSets = import 'aggregation-sets.libsonnet';
local alerts = import 'alerts/alerts.libsonnet';
local multiburnExpression = import 'mwmbr/expression.libsonnet';
local serviceCatalog = import 'service-catalog/service-catalog.libsonnet';
local metricsCatalog = import 'servicemetrics/metrics-catalog.libsonnet';
local serviceLevelAlerts = import 'servicemetrics/service-level-alerts.libsonnet';
local stableIds = import 'stable-ids/stable-ids.libsonnet';
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

local labelsForSLI(sli) =
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


local ignoredSelectorLabels = std.set(['component', 'type', 'tier', 'env']);
local ignoredAggregationLabels = std.set(['component', 'type']);
local ignoredGrafanaVariables = std.set(['tier', 'env']);

local promQueryForSelector(serviceType, sli, aggregationSet, metricName) =
  local selector = std.foldl(
    function(memo, label)
      local value =
        if std.member(ignoredSelectorLabels, label) then null else '{{ $labels.' + label + ' }}';

      if value == null then
        memo
      else
        memo { [label]: value },
    aggregationSet.labels,
    {},
  );

  local aggregationLabels = std.filter(function(l) !std.member(ignoredAggregationLabels, l), aggregationSet.labels);

  if !sli.supportsDetails() then
    null
  else
    if sli.hasHistogramApdex() && metricName == 'apdex' then
      sli.apdex.percentileLatencyQuery(
        percentile=0.95,
        aggregationLabels=aggregationLabels,
        selector=selector,
        rangeInterval='5m',
      )
    else if sli.hasErrorRate() && metricName == 'error' then
      sli.errorRate.aggregatedRateQuery(
        aggregationLabels=aggregationLabels,
        selector=selector,
        rangeInterval='5m',
      )
    else if metricName == 'ops' then
      sli.requestRate.aggregatedRateQuery(
        aggregationLabels=aggregationLabels,
        selector=selector,
        rangeInterval='5m',
      )
    else
      null;


// By convention, we know that the Grafana UID will
// be <service>-main/<service>-overview
local dashboardForService(serviceType) =
  '%(serviceType)s-main/%(serviceType)s-overview' % {
    serviceType: serviceType,
  };

// Generates some common annotations for each SLO alert
local commonAnnotationsForSLI(serviceType, sli, aggregationSet, metricName) =
  local panelSuffix =
    if metricName == 'apdex' then 'apdex'
    else if metricName == 'error' then 'error-rate'
    else if metricName == 'ops' then 'ops-rate'
    else error 'unrecognised metric type: metricName="%s"' % [metricName];

  local panelStableId = 'sli-%s-%s' % [sli.name, panelSuffix];

  {
    // TODO: improve on grafana dashboard links
    grafana_dashboard_id: dashboardForService(serviceType),
    grafana_panel_id: stableIds.hashStableId(panelStableId),
    grafana_variables: 'environment,stage',
    grafana_min_zoom_hours: '6',

    promql_template_1: promQueryForSelector(serviceType, sli, aggregationSet, metricName),
  };

// Generates an apdex alert for an SLI
local apdexAlertForSLI(service, sli) =
  local apdexScoreSLO = sli.monitoringThresholds.apdexScore;
  local formatConfig = {
    sliName: sli.name,
    serviceType: service.type,
  };

  serviceLevelAlerts.apdexAlertsForSLI(
    alertName=serviceLevelAlerts.nameSLOViolationAlert(service.type, sli.name, 'ApdexSLOViolation'),
    alertTitle='The %(sliName)s SLI of the %(serviceType)s service (`{{ $labels.stage }}` stage) has an apdex violating SLO' % formatConfig,
    alertDescriptionLines=[sli.description],
    serviceType=service.type,
    severity=sli.severity,
    thresholdSLOValue=apdexScoreSLO,
    aggregationSet=aggregationSets.componentSLIs,
    windows=service.alertWindows,
    metricSelectorHash={ type: service.type, component: sli.name },
    minimumSamplesForMonitoring=minimumSamplesForMonitoring,
    extraLabels=labelsForSLI(sli),
    extraAnnotations=commonAnnotationsForSLI(service.type, sli, aggregationSets.componentSLIs, 'apdex')
  )
  +
  (
    if service.nodeLevelMonitoring then
      serviceLevelAlerts.apdexAlertsForSLI(
        alertName=serviceLevelAlerts.nameSLOViolationAlert(service.type, sli.name, 'ApdexSLOViolationSingleNode'),
        alertTitle='The %(sliName)s SLI of the %(serviceType)s service on node `{{ $labels.fqdn }}` has an apdex violating SLO' % formatConfig,
        alertDescriptionLines=[
          sli.description,
          'Since the `{{ $labels.type }}` service is not fully redundant, SLI violations on a single node may represent a user-impacting service degradation.',
        ],
        serviceType=service.type,
        severity=sli.severity,
        thresholdSLOValue=apdexScoreSLO,
        aggregationSet=aggregationSets.nodeComponentSLIs,
        windows=service.alertWindows,
        metricSelectorHash={ type: service.type, component: sli.name },
        minimumSamplesForMonitoring=minimumSamplesForNodeMonitoring,
        alertForDuration=nodeAlertWaitPeriod,
        extraLabels=labelsForSLI(sli),
        extraAnnotations=commonAnnotationsForSLI(service.type, sli, aggregationSets.nodeComponentSLIs, 'apdex'),
      )
    else
      []
  )
  +
  (
    if sli.regional then
      serviceLevelAlerts.apdexAlertsForSLI(
        alertName=serviceLevelAlerts.nameSLOViolationAlert(service.type, sli.name, 'ApdexSLOViolationRegional'),
        alertTitle='The %(sliName)s SLI of the %(serviceType)s service in region `{{ $labels.region }}` has an apdex violating SLO' % formatConfig,
        alertDescriptionLines=[
          sli.description,
          'Note that this alert is specific to the `{{ $labels.region }}` region.',
        ],
        serviceType=service.type,
        severity=sli.severity,
        thresholdSLOValue=apdexScoreSLO,
        aggregationSet=aggregationSets.regionalComponentSLIs,
        windows=service.alertWindows,
        metricSelectorHash={ type: service.type, component: sli.name },
        minimumSamplesForMonitoring=minimumSamplesForMonitoring,
        extraLabels=labelsForSLI(sli),
        extraAnnotations=commonAnnotationsForSLI(service.type, sli, aggregationSets.regionalComponentSLIs, 'apdex'),
      )
    else
      []
  );

// Generates an error rate alert for an SLI
local errorRateAlertForSLI(service, sli) =
  local errorRateSLO = sli.monitoringThresholds.errorRatio;
  local formatConfig = {
    sliName: sli.name,
    serviceType: service.type,
  };

  serviceLevelAlerts.errorAlertsForSLI(
    alertName=serviceLevelAlerts.nameSLOViolationAlert(service.type, sli.name, 'ErrorSLOViolation'),
    alertTitle='The %(sliName)s SLI of the %(serviceType)s service (`{{ $labels.stage }}` stage) has an error rate violating SLO' % formatConfig,
    alertDescriptionLines=[sli.description],
    serviceType=service.type,
    severity=sli.severity,
    thresholdSLOValue=errorRateSLO,
    aggregationSet=aggregationSets.componentSLIs,
    windows=service.alertWindows,
    metricSelectorHash={ type: service.type, component: sli.name },
    minimumSamplesForMonitoring=minimumSamplesForMonitoring,
    extraLabels=labelsForSLI(sli),
    extraAnnotations=commonAnnotationsForSLI(service.type, sli, aggregationSets.componentSLIs, 'error'),
  )
  +
  (
    if service.nodeLevelMonitoring then
      serviceLevelAlerts.errorAlertsForSLI(
        alertName=serviceLevelAlerts.nameSLOViolationAlert(service.type, sli.name, 'ErrorSLOViolationSingleNode'),
        alertTitle='The %(sliName)s SLI of the %(serviceType)s service on node `{{ $labels.fqdn }}` has an error rate violating SLO' % formatConfig,
        alertDescriptionLines=[
          sli.description,
          'Since the `{{ $labels.type }}` service is not fully redundant, SLI violations on a single node may represent a user-impacting service degradation.',
        ],
        serviceType=service.type,
        severity=sli.severity,
        thresholdSLOValue=errorRateSLO,
        aggregationSet=aggregationSets.nodeComponentSLIs,
        windows=service.alertWindows,
        metricSelectorHash={ type: service.type, component: sli.name },
        minimumSamplesForMonitoring=minimumSamplesForNodeMonitoring,
        alertForDuration=nodeAlertWaitPeriod,
        extraLabels=labelsForSLI(sli),
        extraAnnotations=commonAnnotationsForSLI(service.type, sli, aggregationSets.nodeComponentSLIs, 'error'),
      )
    else
      []
  )
  +
  (
    if sli.regional then
      serviceLevelAlerts.errorAlertsForSLI(
        alertName=serviceLevelAlerts.nameSLOViolationAlert(service.type, sli.name, 'ErrorSLOViolationRegional'),
        alertTitle='The %(sliName)s SLI of the %(serviceType)s service in region `{{ $labels.region }}` has an error rate violating SLO' % formatConfig,
        alertDescriptionLines=[
          sli.description,
          'Note that this alert is specific to the `{{ $labels.region }}` region.',
        ],
        serviceType=service.type,
        severity=sli.severity,
        thresholdSLOValue=errorRateSLO,
        aggregationSet=aggregationSets.regionalComponentSLIs,
        windows=service.alertWindows,
        metricSelectorHash={ type: service.type, component: sli.name },
        minimumSamplesForMonitoring=minimumSamplesForMonitoring,
        extraLabels=labelsForSLI(sli),
        extraAnnotations=commonAnnotationsForSLI(service.type, sli, aggregationSets.regionalComponentSLIs, 'error'),
      )
    else
      []
  );

local trafficCessationAlert(service, sli) =
  local formatConfig = {
    sliName: sli.name,
    sliDescription: strings.chomp(sli.description),
    serviceType: service.type,
  };

  [
    {
      alert: serviceLevelAlerts.nameSLOViolationAlert(service.type, sli.name, 'TrafficCessation'),
      expr: |||
        gitlab_component_ops:rate_30m{type="%(serviceType)s", component="%(sliName)s", stage="main", monitor="global"} == 0
      ||| % formatConfig,
      'for': '5m',
      labels:
        serviceLevelAlerts.labelsForAlert(sli.severity, aggregationSets.componentSLIs, 'ops', 'traffic_cessation', windowDuration=null)
        +
        labelsForSLI(sli),
      annotations:
        serviceLevelAlerts.commonAnnotations(service.type, aggregationSets.componentSLIs, 'ops') +
        commonAnnotationsForSLI(service.type, sli, aggregationSets.componentSLIs, 'ops') +
        {
          title: 'The %(sliName)s SLI of the %(serviceType)s service (`{{ $labels.stage }}` stage) has not received any traffic in the past 30 minutes' % formatConfig,
          description: |||
            %(sliDescription)s

            This alert signifies that the SLI is reporting a cessation of traffic, but the signal is not absent.
          ||| % formatConfig,
          // grafana_variables: 'environment,stage',
        },
    },
    {
      alert: serviceLevelAlerts.nameSLOViolationAlert(service.type, sli.name, 'TrafficAbsent'),
      expr: |||
        gitlab_component_ops:rate_5m{type="%(serviceType)s", component="%(sliName)s", stage="main", monitor="global"} offset 1h
        unless
        gitlab_component_ops:rate_5m{type="%(serviceType)s", component="%(sliName)s", stage="main", monitor="global"}
      ||| % formatConfig,
      'for': '30m',
      labels:
        serviceLevelAlerts.labelsForAlert(sli.severity, aggregationSets.componentSLIs, 'ops', 'traffic_cessation', windowDuration=null)
        +
        labelsForSLI(sli),
      annotations:
        serviceLevelAlerts.commonAnnotations(service.type, aggregationSets.componentSLIs, 'ops') +
        commonAnnotationsForSLI(service.type, sli, aggregationSets.componentSLIs, 'ops') +

        {
          title: 'The %(sliName)s SLI of the %(serviceType)s service (`{{ $labels.stage }}` stage) has not reported any traffic in the past 30 minutes' % formatConfig,
          description: |||
            %(sliDescription)s

            This alert signifies that the SLI was previously reporting traffic, but is no longer - the signal is absent.

            This could be caused by a change to the metrics used in the SLI, or by the service not receiving traffic.
          ||| % formatConfig,
          // grafana_variables: 'environment,stage',
        },
    },
    /* TODO: consider adding regional traffic alerts in future */
  ];

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
          errorRateAlertForSLI(service, sli)
        else
          []
      )
      +
      (
        if !sli.ignoreTrafficCessation then  // Alert on a zero RPS operation rate for this SLI
          trafficCessationAlert(service, sli)
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
