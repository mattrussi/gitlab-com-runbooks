local aggregationSets = import 'aggregation-sets.libsonnet';
local alerts = import 'alerts/alerts.libsonnet';
local metricsCatalog = import 'metrics-catalog.libsonnet';
local multiburnExpression = import 'mwmbr/expression.libsonnet';
local multiburnFactors = import 'mwmbr/multiburn_factors.libsonnet';
local serviceCatalog = import 'service_catalog.libsonnet';
local stableIds = import 'stable-ids/stable-ids.libsonnet';
local stages = import 'stages.libsonnet';
local strings = import 'utils/strings.libsonnet';

// For now, only include components that run at least once a second
// in the monitoring. This is to avoid low-volume, noisy alerts
local minimumOperationRateForMonitoring = 1; /* rps */
local minimumOperationRateForNodeMonitoring = 10; /* rps */

// Most MWMBR alerts use a 2m period
// Initially for this alert, use a long period to ensure that
// it's not too noisy.
// Consider bringing this down to 2m after 1 Sep 2020
local nodeAlertWaitPeriod = '10m';


local formatConfig = multiburnFactors {
  minimumOperationRateForMonitoring: minimumOperationRateForMonitoring,
};

local labelsForSLI(sli) =
  local labels = {
    user_impacting: if sli.userImpacting then 'yes' else 'no',
    feature_category: std.asciiLower(sli.featureCategory),
    product_stage: std.asciiLower(stages.findStageNameForFeatureCategory(sli.featureCategory)),
    product_stage_group: std.asciiLower(stages.findStageGroupNameForFeatureCategory(sli.featureCategory)),
  };
  if sli.team != null then
    local team = serviceCatalog.getTeam(sli.team);
    if std.objectHas(team, 'issue_tracker') then
      labels {
        incident_project: team.issue_tracker,
      }
    else
      labels
  else
    labels;

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

// Generates an apdex alert for an SLI
local apdexAlertForSLI(service, sli) =
  local apdexScoreSLO = service.monitoringThresholds.apdexScore;
  local formatConfig = {
    sliName: sli.name,
    sliDescription: strings.chomp(sli.description),
    serviceType: service.type,
  };

  [{
    alert: nameSLOViolationAlert(service.type, sli.name, 'ApdexSLOViolation'),
    expr: multiburnExpression.multiburnRateApdexExpression(
      aggregationSet=aggregationSets.globalSLIs,
      metricSelectorHash={ type: service.type, component: sli.name },
      minimumOperationRateForMonitoring=minimumOperationRateForMonitoring,
      thresholdSLOValue=apdexScoreSLO
    ),
    'for': '2m',
    labels: labelsForSLI(sli) {
      alert_type: 'symptom',
      rules_domain: 'general',
      severity: 's2',
      pager: 'pagerduty',
      slo_alert: 'yes',
    },
    annotations: {
      title: 'The %(sliName)s SLI of the %(serviceType)s service (`{{ $labels.stage }}` stage) has an apdex violating SLO' % formatConfig,
      description: |||
        %(sliDescription)s

        Currently the apdex value is {{ $value | humanizePercentage }}.
      ||| % formatConfig,
      runbook: 'docs/{{ $labels.type }}/README.md',
      grafana_dashboard_id: dashboardForService(service),
      grafana_panel_id: stableIds.hashStableId('sli-%(sliName)s-apdex' % formatConfig),
      grafana_variables: 'environment,stage',
      grafana_min_zoom_hours: '6',
      promql_template_1: 'gitlab_component_apdex:ratio_1h{environment="$environment", type="$type", stage="$stage", component="$component"}',
    },
  }]
  +
  (
    if service.nodeLevelMonitoring then
      [{
        alert: nameSLOViolationAlert(service.type, sli.name, 'ApdexSLOViolationSingleNode'),
        expr: multiburnExpression.multiburnRateApdexExpression(
          aggregationSet=aggregationSets.globalNodeSLIs,
          metricSelectorHash={ type: service.type, component: sli.name },
          minimumOperationRateForMonitoring=minimumOperationRateForNodeMonitoring,
          thresholdSLOValue=apdexScoreSLO
        ),
        'for': nodeAlertWaitPeriod,
        labels: labelsForSLI(sli) {
          alert_type: 'symptom',
          rules_domain: 'general',
          severity: 's2',
          pager: 'pagerduty',
          slo_alert: 'yes',
        },
        annotations: {
          title: 'The %(sliName)s SLI of the %(serviceType)s service on node `{{ $labels.fqdn }}` has an apdex violating SLO' % formatConfig,
          description: |||
            %(sliDescription)s

            Since the %(serviceType)s service is not fully redundant, SLI violations on a single node may represent a user-impacting service degradation.

            Currently the apdex value for {{ $labels.fqdn }} is {{ $value | humanizePercentage }}.
          ||| % formatConfig,
          runbook: 'docs/{{ $labels.type }}/README.md',
          grafana_dashboard_id: 'alerts-component_node_multiburn_apdex/alerts-component-node-multi-window-multi-burn-rate-apdex-out-of-slo',
          grafana_panel_id: stableIds.hashStableId('multiwindow-multiburnrate'),
          grafana_variables: 'environment,type,stage,component,fqdn',
          grafana_min_zoom_hours: '6',
          promql_template_1: 'gitlab_component_node_apdex:ratio_1h{environment="$environment", type="$type", stage="$stage", component="$component", fqdn="$fqdn"}',
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
    labels: labelsForSLI(sli) {
      rules_domain: 'general',
      severity: 's2',
      slo_alert: 'yes',
      alert_type: 'symptom',
      pager: 'pagerduty',
    },
    annotations: {
      title: 'The %(sliName)s SLI of the %(serviceType)s service (`{{ $labels.stage }}` stage) has an error rate violating SLO' % formatConfig,
      description: |||
        %(sliDescription)s

        Currently the error-rate is {{ $value | humanizePercentage }}.
      ||| % formatConfig,
      runbook: 'docs/{{ $labels.type }}/README.md',
      grafana_dashboard_id: dashboardForService(service),
      grafana_panel_id: stableIds.hashStableId('sli-%(sliName)s-error-rate' % formatConfig),
      grafana_variables: 'environment,stage',
      grafana_min_zoom_hours: '6',
      link1_title: 'Definition',
      link1_url: 'https://gitlab.com/gitlab-com/runbooks/blob/master/docs/uncategorized/definition-service-error-rate.md',
      promql_template_1: 'gitlab_component_errors:ratio_5m{environment="$environment", type="$type", stage="$stage", component="$component"}',
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
          minimumOperationRateForMonitoring=minimumOperationRateForNodeMonitoring,
          thresholdSLOValue=1 - errorRateSLO,
        ),
        'for': nodeAlertWaitPeriod,
        labels: labelsForSLI(sli) {
          rules_domain: 'general',
          severity: 's2',
          slo_alert: 'yes',
          alert_type: 'symptom',
          pager: 'pagerduty',
        },
        annotations: {
          title: 'The %(sliName)s SLI of the %(serviceType)s service on node `{{ $labels.fqdn }}` has an error rate violating SLO' % formatConfig,
          description: |||
            %(sliDescription)s

            Since the %(serviceType)s service is not fully redundant, SLI violations on a single node may represent a user-impacting service degradation.

            Currently the apdex value for {{ $labels.fqdn }} is {{ $value | humanizePercentage }}.
          ||| % formatConfig,
          runbook: 'docs/{{ $labels.type }}/README.md',
          grafana_dashboard_id: 'alerts-component_node_multiburn_error/alerts-component-node-multi-window-multi-burn-rate-error-rate-out-of-slo',
          grafana_panel_id: stableIds.hashStableId('multiwindow-multiburnrate'),
          grafana_variables: 'environment,type,stage,component,fqdn',
          grafana_min_zoom_hours: '6',
          promql_template_1: 'gitlab_component_node_errors:ratio_5m{environment="$environment", type="$type", stage="$stage", component="$component", fqdn="$fqdn"}',
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
      labels: labelsForSLI(sli) {
        experimental: true,
        severity: 's3',
        slo_alert: 'no',
        alert_type: 'cause',
        // pager: 'pagerduty', // TODO: send to pagerduty
      },
      annotations: {
        title: 'The %(sliName)s SLI of the %(serviceType)s service (`{{ $labels.stage }}` stage) has not received any traffic in the past 30 minutes' % formatConfig,
        description: |||
          %(sliDescription)s

          This alert signifies that the SLI is reporting a cessation of traffic, but the signal is not absent.
        ||| % formatConfig,
        runbook: 'docs/{{ $labels.type }}/README.md',
        grafana_dashboard_id: dashboardForService(service),
        grafana_panel_id: stableIds.hashStableId('sli-%(sliName)s-ops-rate' % formatConfig),
        grafana_variables: 'environment,stage',
        grafana_min_zoom_hours: '6',
        link1_title: 'Definition',
        link1_url: 'https://gitlab.com/gitlab-com/runbooks/blob/master/docs/uncategorized/definition-service-ops-rate.md',
        promql_template_1: 'gitlab_component_errors:ratio_5m{environment="$environment", type="$type", stage="$stage", component="$component"}',
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
      labels: labelsForSLI(sli) {
        experimental: true,
        severity: 's3',
        slo_alert: 'no',
        alert_type: 'cause',
        // pager: 'pagerduty', // TODO: send to pagerduty
      },
      annotations: {
        title: 'The %(sliName)s SLI of the %(serviceType)s service (`{{ $labels.stage }}` stage) has not reported any traffic in the past 30 minutes' % formatConfig,
        description: |||
          %(sliDescription)s

          This alert signifies that the SLI was previously reporting traffic, but is no longer - the signal is absent.

          This could be caused by a change to the metrics used in the SLI, or by the service not receiving traffic.
        ||| % formatConfig,
        runbook: 'docs/{{ $labels.type }}/README.md',
        grafana_dashboard_id: dashboardForService(service),
        grafana_panel_id: stableIds.hashStableId('sli-%(sliName)s-ops-rate' % formatConfig),
        grafana_variables: 'environment,stage',
        grafana_min_zoom_hours: '6',
        link1_title: 'Definition',
        link1_url: 'https://gitlab.com/gitlab-com/runbooks/blob/master/docs/uncategorized/definition-service-ops-rate.md',
        promql_template_1: 'gitlab_component_ops:rate_5m{environment="$environment", type="$type", stage="$stage", component="$component"}',
      },
    },
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

// Not all services have alertable SLIs, filter the list
local servicesWithSLIAlerts = std.filter(
  function(service)
    local slis = service.listServiceLevelIndicators();
    local hasMonitoringThresholds = std.objectHas(service, 'monitoringThresholds');
    local hasApdexSLO = hasMonitoringThresholds && std.objectHas(service.monitoringThresholds, 'apdexScore');
    local hasErrorRateSLO = hasMonitoringThresholds && std.objectHas(service.monitoringThresholds, 'errorRatio');

    // Returns true if any of the SLIs have an apdex or an error rate
    std.foldl(
      function(hasAlerts, sli)
        hasAlerts || (hasApdexSLO && sli.hasApdex()) || (hasErrorRateSLO && sli.hasErrorRate()) || !sli.ignoreTrafficCessation,
      slis,
      false
    )
);

std.foldl(
  function(docs, service)
    docs {
      ['service-level-alerts-%s.yml' % [service.type]]: std.manifestYamlDoc(groupsForService(service)),
    },
  metricsCatalog.services,
  {},
)
