local aggregationSets = import 'aggregation-sets.libsonnet';
local alerts = import 'alerts/alerts.libsonnet';
local metricsCatalog = import 'metrics-catalog.libsonnet';
local multiburnExpression = import 'mwmbr/expression.libsonnet';
local serviceCatalog = import 'service_catalog.libsonnet';
local stableIds = import 'stable-ids/stable-ids.libsonnet';
local stages = import 'stages.libsonnet';
local strings = import 'utils/strings.libsonnet';

// Minimum operation rate thresholds:
// This is to avoid low-volume, noisy alerts.
// NOTE: at present we are transitioning from minimumOperationRateForMonitoring to minimumSamplesForMonitoring.
// Initially only a subset of alerts are using minimumSamplesForMonitoring, but we expect this to expand
// until all alerts are using this approach. At that point, we can drop minimumOperationRateForMonitoring.
local minimumOperationRateForMonitoring = 1; /* rps */
local minimumSamplesForMonitoring = 1200;

// Most MWMBR alerts use a 2m period
// Initially for this alert, use a long period to ensure that
// it's not too noisy.
// Consider bringing this down to 2m after 1 Sep 2020
local nodeAlertWaitPeriod = '10m';

local labelsForSLI(sli, severity, aggregationSet, sliType, alertClass) =
  local pager = if severity == 's1' || severity == 's2' then 'pagerduty' else null;

  local labels = {
    alert_class: alertClass,
    aggregation: aggregationSet.id,
    sli_type: sliType,
    rules_domain: 'general',
    severity: severity,
    pager: pager,
    user_impacting: if sli.userImpacting then 'yes' else 'no',
    feature_category: std.asciiLower(sli.featureCategory),
    product_stage: std.asciiLower(stages.findStageNameForFeatureCategory(sli.featureCategory)),
    product_stage_group: std.asciiLower(stages.findStageGroupNameForFeatureCategory(sli.featureCategory)),
    // slo_alert same as alert_type, consider dropping
    slo_alert: if sliType == 'apdex' || sliType == 'error' then 'yes' else 'no',
    alert_type: if sliType == 'apdex' || sliType == 'error' then 'symptom' else 'cause',
  };

  local team = if sli.team != null then serviceCatalog.getTeam(sli.team) else null;

  labels + (
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


local toCamelCase(str) =
  std.join(
    '',
    std.map(
      strings.capitalizeFirstLetter,
      strings.splitOnChars(str, '-_')
    )
  );

// Generates an alert name
local nameSLOViolationAlert(serviceType, sliName, violationType) =
  '%(serviceType)sService%(sliName)s%(violationType)s' % {
    serviceType: toCamelCase(serviceType),
    sliName: toCamelCase(sliName),
    violationType: violationType,
  };


// For now, this is a bit of a hack, relying on a convention that service overview
// dashboards will match this URL
local dashboardForService(service) =
  '%(serviceType)s-main/%(serviceType)s-overview' % {
    serviceType: service.type,
  };


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
    if sli.hasApdex() && metricName == 'apdex' then
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

// Generates some common annotations for each SLO alert
local commonAnnotations(serviceType, sli, aggregationSet, metricName) =
  local formatConfig = {
    serviceType: serviceType,
    metricName: metricName,
    aggregationId: aggregationSet.id,
  };

  local grafanaVariables = std.filter(function(l) !std.member(ignoredGrafanaVariables, l), aggregationSet.labels);

  {
    runbook: 'docs/%(serviceType)s/README.md' % formatConfig,  // We can do better than this
    grafana_dashboard_id: 'alerts-%(aggregationId)s_slo_%(metricName)s' % formatConfig,
    grafana_panel_id: stableIds.hashStableId('multiwindow-multiburnrate'),
    grafana_variables: std.join(',', grafanaVariables),
    grafana_min_zoom_hours: '6',
    promql_template_1: promQueryForSelector(serviceType, sli, aggregationSet, metricName),
  };

// Generates an apdex alert for an SLI
local apdexAlertForSLI(service, sli) =
  local apdexScoreSLO = service.monitoringThresholds.apdexScore;
  local formatConfig = {
    sliName: sli.name,
    sliDescription: strings.chomp(sli.description),
    serviceType: service.type,
  };

  local globalWindows = if std.objectHas(service, 'alertWindows') then
    [[window] for window in service.alertWindows]
  else  // Include all windows in a single alert
    [multiburnExpression.defaultWindows];

  // If we have an array with a single window in it, we want to add that
  // label to the alert.
  local windowLabel(windows) =
    if std.length(windows) == 1 then
      { window: windows[0] }
    else
      {};

  [{
    alert: nameSLOViolationAlert(service.type, sli.name, 'ApdexSLOViolation'),
    expr: multiburnExpression.multiburnRateApdexExpression(
      aggregationSet=aggregationSets.globalSLIs,
      metricSelectorHash={ type: service.type, component: sli.name },
      minimumOperationRateForMonitoring=minimumOperationRateForMonitoring,
      thresholdSLOValue=apdexScoreSLO,
      windows=windows
    ),
    'for': '2m',
    labels: labelsForSLI(sli, 's2', aggregationSets.globalSLIs, 'apdex', 'slo_violation') + windowLabel(windows),
    annotations: commonAnnotations(service.type, sli, aggregationSets.globalSLIs, 'apdex') {
      title: 'The %(sliName)s SLI of the %(serviceType)s service (`{{ $labels.stage }}` stage) has an apdex violating SLO' % formatConfig,
      description: |||
        %(sliDescription)s

        Currently the apdex value is {{ $value | humanizePercentage }}.
      ||| % formatConfig,
      grafana_dashboard_id: dashboardForService(service),
      grafana_panel_id: stableIds.hashStableId('sli-%(sliName)s-apdex' % formatConfig),
    },
  } for windows in globalWindows]
  +
  (
    if service.nodeLevelMonitoring then
      [{
        alert: nameSLOViolationAlert(service.type, sli.name, 'ApdexSLOViolationSingleNode'),
        expr: multiburnExpression.multiburnRateApdexExpression(
          aggregationSet=aggregationSets.globalNodeSLIs,
          metricSelectorHash={ type: service.type, component: sli.name },
          minimumSamplesForMonitoring=minimumSamplesForMonitoring,
          thresholdSLOValue=apdexScoreSLO,
          windows=[windowDuration],
          operationRateWindowDuration=windowDuration
        ),
        'for': nodeAlertWaitPeriod,
        labels: labelsForSLI(sli, 's2', aggregationSets.globalNodeSLIs, 'apdex', 'slo_violation') { window: windowDuration },
        annotations: commonAnnotations(service.type, sli, aggregationSets.globalNodeSLIs, 'apdex') {
          title: 'The %(sliName)s SLI of the %(serviceType)s service on node `{{ $labels.fqdn }}` has an apdex violating SLO' % formatConfig,
          description: |||
            %(sliDescription)s

            Since the %(serviceType)s service is not fully redundant, SLI violations on a single node may represent a user-impacting service degradation.

            Currently the apdex value for {{ $labels.fqdn }} is {{ $value | humanizePercentage }}.
          ||| % formatConfig,
        },
      } for windowDuration in ['1h', '6h']]
    else
      []
  )
  +
  (
    if sli.regional then
      [{
        alert: nameSLOViolationAlert(service.type, sli.name, 'ApdexSLOViolationRegional'),
        expr: multiburnExpression.multiburnRateApdexExpression(
          aggregationSet=aggregationSets.regionalSLIs,
          metricSelectorHash={ type: service.type, component: sli.name },
          minimumOperationRateForMonitoring=minimumOperationRateForMonitoring,
          thresholdSLOValue=apdexScoreSLO
        ),
        'for': '2m',
        labels: labelsForSLI(sli, 's2', aggregationSets.regionalSLIs, 'apdex', 'slo_violation'),
        annotations: commonAnnotations(service.type, sli, aggregationSets.regionalSLIs, 'apdex') {
          title: 'The %(sliName)s SLI of the %(serviceType)s service in region `{{ $labels.region }}` has an apdex violating SLO' % formatConfig,
          description: |||
            %(sliDescription)s

            Currently the apdex value is {{ $value | humanizePercentage }}.
          ||| % formatConfig,
        },
      }]
    else
      []
  );

// Generates an error rate alert for an SLI
local errorRateAlertForSLI(service, sli) =
  local errorRateSLO = service.monitoringThresholds.errorRatio;
  local formatConfig = {
    sliName: sli.name,
    sliDescription: strings.chomp(sli.description),
    serviceType: service.type,
  };

  [{
    alert: nameSLOViolationAlert(service.type, sli.name, 'ErrorSLOViolation'),
    expr: multiburnExpression.multiburnRateErrorExpression(
      aggregationSet=aggregationSets.globalSLIs,
      metricSelectorHash={ type: service.type, component: sli.name },
      minimumOperationRateForMonitoring=minimumOperationRateForMonitoring,
      thresholdSLOValue=1 - errorRateSLO,
    ),
    'for': '2m',
    labels: labelsForSLI(sli, 's2', aggregationSets.globalSLIs, 'error', 'slo_violation'),
    annotations: commonAnnotations(service.type, sli, aggregationSets.globalSLIs, 'error') {
      title: 'The %(sliName)s SLI of the %(serviceType)s service (`{{ $labels.stage }}` stage) has an error rate violating SLO' % formatConfig,
      description: |||
        %(sliDescription)s

        Currently the error-rate is {{ $value | humanizePercentage }}.
      ||| % formatConfig,
      grafana_dashboard_id: dashboardForService(service),
      grafana_variables: 'environment,stage',
      grafana_panel_id: stableIds.hashStableId('sli-%(sliName)s-error-rate' % formatConfig),
    },
  }]
  +
  (
    if service.nodeLevelMonitoring then
      [{
        alert: nameSLOViolationAlert(service.type, sli.name, 'ErrorSLOViolationSingleNode'),
        expr: multiburnExpression.multiburnRateErrorExpression(
          aggregationSet=aggregationSets.globalNodeSLIs,
          metricSelectorHash={ type: service.type, component: sli.name },
          minimumSamplesForMonitoring=minimumSamplesForMonitoring,
          thresholdSLOValue=1 - errorRateSLO,
          windows=[windowDuration],
          operationRateWindowDuration=windowDuration
        ),
        'for': nodeAlertWaitPeriod,
        labels: labelsForSLI(sli, 's2', aggregationSets.globalNodeSLIs, 'error', 'slo_violation') { window: windowDuration },
        annotations: commonAnnotations(service.type, sli, aggregationSets.globalNodeSLIs, 'error') {
          title: 'The %(sliName)s SLI of the %(serviceType)s service on node `{{ $labels.fqdn }}` has an error rate violating SLO' % formatConfig,
          description: |||
            %(sliDescription)s

            Since the %(serviceType)s service is not fully redundant, SLI violations on a single node may represent a user-impacting service degradation.

            Currently the apdex value for {{ $labels.fqdn }} is {{ $value | humanizePercentage }}.
          ||| % formatConfig,
        },
      } for windowDuration in ['1h', '6h']]
    else
      []
  )
  +
  (
    if sli.regional then
      [{
        alert: nameSLOViolationAlert(service.type, sli.name, 'ErrorSLOViolationRegional'),
        expr: multiburnExpression.multiburnRateErrorExpression(
          aggregationSet=aggregationSets.regionalSLIs,
          metricSelectorHash={ type: service.type, component: sli.name },
          minimumOperationRateForMonitoring=minimumOperationRateForMonitoring,
          thresholdSLOValue=1 - errorRateSLO,
        ),
        'for': '2m',
        labels: labelsForSLI(sli, 's2', aggregationSets.regionalSLIs, 'error', 'slo_violation'),
        annotations: commonAnnotations(service.type, sli, aggregationSets.regionalSLIs, 'error') {
          title: 'The %(sliName)s SLI of the %(serviceType)s service in region `{{ $labels.region }}` has an error rate violating SLO' % formatConfig,
          description: |||
            %(sliDescription)s

            Since the %(serviceType)s service is not fully redundant, SLI violations on a single node may represent a user-impacting service degradation.

            Currently the apdex value for {{ $labels.region }} is {{ $value | humanizePercentage }}.
          ||| % formatConfig,
        },
      }]
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
      alert: nameSLOViolationAlert(service.type, sli.name, 'TrafficCessation'),
      expr: |||
        gitlab_component_ops:rate_30m{type="%(serviceType)s", component="%(sliName)s", stage="main", monitor="global"} == 0
      ||| % formatConfig,
      'for': '5m',
      labels: labelsForSLI(sli, 's2', aggregationSets.globalSLIs, 'ops', 'traffic_cessation'),
      annotations: commonAnnotations(service.type, sli, aggregationSets.globalSLIs, 'ops') {
        title: 'The %(sliName)s SLI of the %(serviceType)s service (`{{ $labels.stage }}` stage) has not received any traffic in the past 30 minutes' % formatConfig,
        description: |||
          %(sliDescription)s

          This alert signifies that the SLI is reporting a cessation of traffic, but the signal is not absent.
        ||| % formatConfig,
        grafana_dashboard_id: dashboardForService(service),
        grafana_variables: 'environment,stage',
        grafana_panel_id: stableIds.hashStableId('sli-%(sliName)s-ops-rate' % formatConfig),
      },
    },
    {
      alert: nameSLOViolationAlert(service.type, sli.name, 'TrafficAbsent'),
      expr: |||
        gitlab_component_ops:rate_5m{type="%(serviceType)s", component="%(sliName)s", stage="main", monitor="global"} offset 1h
        unless
        gitlab_component_ops:rate_5m{type="%(serviceType)s", component="%(sliName)s", stage="main", monitor="global"}
      ||| % formatConfig,
      'for': '30m',
      labels: labelsForSLI(sli, 's2', aggregationSets.globalSLIs, 'ops', 'traffic_cessation'),
      annotations: commonAnnotations(service.type, sli, aggregationSets.globalSLIs, 'ops') {
        title: 'The %(sliName)s SLI of the %(serviceType)s service (`{{ $labels.stage }}` stage) has not reported any traffic in the past 30 minutes' % formatConfig,
        description: |||
          %(sliDescription)s

          This alert signifies that the SLI was previously reporting traffic, but is no longer - the signal is absent.

          This could be caused by a change to the metrics used in the SLI, or by the service not receiving traffic.
        ||| % formatConfig,
        grafana_dashboard_id: dashboardForService(service),
        grafana_variables: 'environment,stage',
        grafana_panel_id: stableIds.hashStableId('sli-%(sliName)s-ops-rate' % formatConfig),
      },
    },
    /* TODO: consider adding regional traffic alerts in future */
  ];

local alertsForService(service) =
  local slis = service.listServiceLevelIndicators();
  local hasMonitoringThresholds = std.objectHas(service, 'monitoringThresholds');
  local hasApdexSLO = hasMonitoringThresholds && std.objectHas(service.monitoringThresholds, 'apdexScore');
  local hasErrorRateSLO = hasMonitoringThresholds && std.objectHas(service.monitoringThresholds, 'errorRatio');

  local rules = std.flatMap(
    function(sli)
      (
        if hasApdexSLO && sli.hasApdex() then
          apdexAlertForSLI(service, sli)
        else
          []
      )
      +
      (
        if hasErrorRateSLO && sli.hasErrorRate() then
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
