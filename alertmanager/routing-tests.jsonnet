local configFile = std.extVar('configFile');

local generateTest(index, testcase) =
  '(amtool config routes test --verify.receivers=%(receivers)s --config.file %(configFile)s %(labels)s >/dev/null) && echo "✔︎ %(name)s" || { echo "𐄂 Testcase #%(index)d %(name)s failed. Expected %(receivers)s got $(amtool config routes test --config.file %(configFile)s %(labels)s)"; exit 1; }' % {
    configFile: configFile,
    labels: std.join(' ', std.map(function(key) key + '=' + testcase.labels[key], std.objectFields(testcase.labels))),
    receivers: std.join(',', testcase.receivers),
    index: index,
    name: testcase.name,
  };

local generateTests(testcases) =
  std.join('\n', std.mapWithIndex(generateTest, testcases));

/**
 * This file contains a test of tests to ensure that out alert routing rules
 * work as we expect them too
 */
generateTests([
  {
    name: 'no labels',
    labels: {},
    receivers: [
      'prod_alerts_slack_channel',
    ],
  },
  {
    name: 'no matching labels',
    labels: {
      __unknown: 'x',
    },
    receivers: [
      'prod_alerts_slack_channel',
    ],
  },
  {
    name: 'pagerduty',
    labels: {
      env: 'gprd',
      pager: 'pagerduty',
    },
    receivers: [
      'prod_pagerduty',
      'production_slack_channel',
    ],
  },
  {
    name: 'production pagerduty and rules_domain=general',
    labels: {
      pager: 'pagerduty',
      rules_domain: 'general',
      env: 'gprd',
    },
    receivers: [
      'prod_pagerduty',
      'slack_bridge-prod',
      'production_slack_channel',
    ],
  },
  {
    name: 'gstg pagerduty and rules_domain=general',
    labels: {
      pager: 'pagerduty',
      rules_domain: 'general',
      env: 'gstg',
    },
    receivers: [
      'slack_bridge-nonprod',
      'blackhole',
    ],
  },
  {
    name: 'pager=pagerduty, no env label',
    labels: {
      pager: 'pagerduty',
    },
    receivers: [
      'production_slack_channel',
    ],
  },

  {
    name: 'team=gitaly, pager=pagerduty, rules_domain=general',
    labels: {
      pager: 'pagerduty',
      rules_domain: 'general',
      team: 'gitaly',
      env: 'gprd',
    },
    receivers: [
      'prod_pagerduty',
      'slack_bridge-prod',
      'team_gitaly_alerts_channel',
      'production_slack_channel',
    ],
  },
  {
    name: 'team alerts for non-prod productions should not go to team channels',
    labels: {
      pager: 'pagerduty',
      rules_domain: 'general',
      team: 'gitaly',
      env: 'gstg',
    },
    receivers: [
      'slack_bridge-nonprod',
      'blackhole',
    ],
  },
  {
    name: 'non-existent team',
    labels: {
      team: 'non_existent',
      env: 'gprd',
    },
    receivers: [
      'prod_alerts_slack_channel',
    ],
  },
  {
    name: 'issue alert, gstg environment',
    labels: {
      incident_project: 'gitlab.com/gitlab-com/gl-infra/infrastructure',
      env: 'gstg',
    },
    receivers: [
      'blackhole',
    ],
  },
  {
    name: 'issue alert, gprd environment',
    labels: {
      incident_project: 'gitlab.com/gitlab-com/gl-infra/infrastructure',
      env: 'gprd',
    },
    receivers: [
      'issue:gitlab.com/gitlab-com/gl-infra/infrastructure',
      'prod_alerts_slack_channel',
    ],
  },
  {
    name: 'issue alert, ops environment',
    labels: {
      incident_project: 'gitlab.com/gitlab-com/gl-infra/infrastructure',
      env: 'ops',
    },
    receivers: [
      'issue:gitlab.com/gitlab-com/gl-infra/infrastructure',
      'prod_alerts_slack_channel',
    ],
  },
  {
    name: 'paging issue alert, gprd environment',
    labels: {
      pager: 'pagerduty',
      incident_project: 'gitlab.com/gitlab-com/gl-infra/production',
      env: 'gprd',
    },
    receivers: [
      'issue:gitlab.com/gitlab-com/gl-infra/production',
      'prod_pagerduty',
      'production_slack_channel',
    ],
  },
  {
    name: 'issue alert, unknown project',
    labels: {
      incident_project: 'nothing',
      env: 'gprd',
    },
    receivers: [
      'prod_alerts_slack_channel',
    ],
  },
  {
    name: 'alertname="SnitchHeartBeat", env="ops"',
    labels: {
      alertname: 'SnitchHeartBeat',
      env: 'ops',
    },
    receivers: [
      'dead_mans_snitch_ops',
    ],
  },
  {
    name: 'alertname="SnitchHeartBeat", unknown environment',
    labels: {
      alertname: 'SnitchHeartBeat',
      env: 'space',
    },
    receivers: [
      'prod_alerts_slack_channel',
    ],
  },
  {
    name: 'alertname="SnitchHeartBeat", no environment',
    labels: {
      alertname: 'SnitchHeartBeat',
    },
    receivers: [
      'prod_alerts_slack_channel',
    ],
  },
  {
    name: 'pager=pagerduty, team=gitaly, env=gprd, slo_alert=yes, stage=cny, rules_domain=general',
    labels: {
      pager: 'pagerduty',
      rules_domain: 'general',
      team: 'gitaly',
      env: 'gprd',
      slo_alert: 'yes',
      stage: 'cny',
    },
    receivers: [
      'slo_gprd_cny',  // Pagerduty
      'slack_bridge-prod',  // Slackline
      'team_gitaly_alerts_channel',  // Gitaly team alerts channel
      'production_slack_channel',  // production channel for pager alerts
    ],
  },
  {
    name: 'pager=pagerduty, team=gitaly, env=pre, slo_alert=yes, stage=cny, rules_domain=general',
    labels: {
      pager: 'pagerduty',
      rules_domain: 'general',
      team: 'gitaly',
      env: 'pre',
      slo_alert: 'yes',
      stage: 'cny',
    },
    receivers: [
      'blackhole',
    ],
  },
  {
    name: 'pager=pagerduty, team=runner, env=gprd',
    labels: {
      pager: 'pagerduty',
      team: 'runner',
      env: 'gprd',
    },
    receivers: [
      'prod_pagerduty',
      'team_runner_alerts_channel',
      'production_slack_channel',
    ],
  },
  {
    name: 'pager=pagerduty, team=gitlab-pages',
    labels: {
      pager: 'pagerduty',
      team: 'gitlab-pages',
      env: 'gprd',
    },
    receivers: [
      'prod_pagerduty',
      'team_gitlab_pages_alerts_channel',
      'production_slack_channel',
    ],
  },
  {
    name: 'non pagerduty, team=gitlab-pages',
    labels: {
      team: 'gitlab-pages',
      severity: 's4',
      env: 'gprd',
    },
    receivers: [
      'team_gitlab_pages_alerts_channel',
      'prod_alerts_slack_channel',
    ],
  },
  {
    name: 'pagerduty, product_stage_group=runner',
    labels: {
      pager: 'pagerduty',
      product_stage_group: 'runner',
      severity: 's1',
      env: 'gprd',
    },
    receivers: [
      'prod_pagerduty',
      'team_runner_alerts_channel',
      'production_slack_channel',
    ],
  },
  {
    name: 'nonpagerduty, team=runner, product_stage_group=runner',
    labels: {
      rules_domain: 'general',
      product_stage_group: 'runner',
      env: 'gprd',
    },
    receivers: [
      'slack_bridge-prod',
      'team_runner_alerts_channel',
      'prod_alerts_slack_channel',
    ],
  },
  {
    name: 'unknown product_stage_group: pagerduty product_stage_group=wombats',
    labels: {
      pager: 'pagerduty',
      severity: 's1',
      product_stage_group: 'wombats',
      env: 'gprd',
    },
    receivers: [
      'prod_pagerduty',
      'production_slack_channel',
    ],
  },
  {
    name: 'gstg traffic anomaly service_ops_out_of_bounds_lower_5m alerts should go to blackhole',
    labels: {
      alertname: 'service_ops_out_of_bounds_lower_5m',
      rules_domain: 'general',
      env: 'gstg',
    },
    receivers: [
      'blackhole',
    ],
  },
  {
    name: 'gstg traffic anomaly service_ops_out_of_bounds_upper_5m alerts should go to blackhole',
    labels: {
      alertname: 'service_ops_out_of_bounds_upper_5m',
      rules_domain: 'general',
      env: 'gstg',
    },
    receivers: [
      'blackhole',
    ],
  },
  {
    name: 'gstg traffic_cessation alerts should go to blackhole',
    labels: {
      alert_class: 'traffic_cessation',
      rules_domain: 'general',
      env: 'gstg',
    },
    receivers: [
      'blackhole',
    ],
  },
])
