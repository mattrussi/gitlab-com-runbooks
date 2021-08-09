// Generate Alertmanager configurations
local secrets = std.extVar('secrets_file');
local serviceCatalog = import 'service_catalog.libsonnet';

// Where the alertmanager templates are deployed.
local templateDir = '/etc/alertmanager/config';

local slackChannelDefaults = {};

//
// Receiver helpers and definitions.
local slackChannels = [
  // Generic channels.
  { name: 'prod_alerts_slack_channel', channel: 'alerts' },
  { name: 'production_slack_channel', channel: 'production', sendResolved: false },
  { name: 'nonprod_alerts_slack_channel', channel: 'alerts-nonprod' },
];

local SnitchReceiver(channel) =
  local env = channel.name;
  local cluster = channel.cluster;
  local receiver_name = if cluster == '' then env else env + '_' + cluster;
  'dead_mans_snitch_' + receiver_name;

local webhookChannels =
  [
    { name: SnitchReceiver(s), url: 'https://nosnch.in/' + s.apiKey, sendResolved: false }
    for s in secrets.snitchChannels
  ] +
  [
    {
      name: w.name,
      url: w.url,
      sendResolved: true,
      httpConfig: {
        bearer_token: w.token,
      },
    }
    for w in secrets.webhookChannels
  ] +
  [
    {
      name: 'issue:' + s.name,
      url: 'https://' + s.name + '/alerts/notify.json',
      sendResolved: true,
      httpConfig: {
        bearer_token: s.token,
      },
    }
    for s in secrets.issueChannels
  ];

local PagerDutyReceiver(channel) = {
  name: channel.name,
  pagerduty_configs: [
    {
      service_key: channel.serviceKey,
      description: '{{ template "slack.title" . }}',
      client: 'GitLab Alertmanager',
      details: {
        note: '{{ template "slack.text" . }}',
      },
      send_resolved: true,
    },
  ],
};

local slackActionButton(text, url) =
  {
    type: 'button',
    text: text,
    url: std.stripChars(url, ' \n'),
  };

local SlackReceiver(channel) =
  local channelWithDefaults = slackChannelDefaults + channel;
  {
    name: channelWithDefaults.name,
    slack_configs: [
      {
        channel: '#' + channelWithDefaults.channel,
        color: '{{ template "slack.color" . }}',
        icon_emoji: '{{ template "slack.icon" . }}',
        send_resolved: if std.objectHas(channel, 'sendResolved') then channel.sendResolved else true,
        text: '{{ template "slack.text" . }}',
        title: '{{ template "slack.title" . }}',
        title_link: '{{ template "slack.link" . }}',
        actions: [
          slackActionButton(  // runbook
            text='Runbook :green_book:',
            url=|||
              {{-  if ne (index .Alerts 0).Annotations.link "" -}}
                {{- (index .Alerts 0).Annotations.link -}}
              {{- else if ne (index .Alerts 0).Annotations.runbook "" -}}
                https://ops.gitlab.net/gitlab-com/runbooks/blob/master/{{ (index .Alerts 0).Annotations.runbook -}}
              {{- else -}}
                https://ops.gitlab.net/gitlab-com/runbooks/blob/master/docs/uncategorized/alerts-should-have-runbook-annotations.md
              {{- end -}}
            |||
          ),
          slackActionButton(  // Grafana link
            text='Dashboard :grafana:',
            url=|||
              {{-  if ne (index .Alerts 0).Annotations.grafana_dashboard_link "" -}}
                {{- (index .Alerts 0).Annotations.grafana_dashboard_link -}}
              {{- else if ne .CommonLabels.type "" -}}
                https://dashboards.gitlab.net/d/{{.CommonLabels.type}}-main?{{ if ne .CommonLabels.stage "" }}var-stage={{.CommonLabels.stage}}{{ end }}
              {{- else -}}
                https://dashboards.gitlab.net/
              {{- end -}}
            |||
          ),
          slackActionButton(  // Silence button
            text='Create Silence :shushing_face:',
            url=|||
              https://alerts.gitlab.net/#/silences/new?filter=%7B
              {{- range .CommonLabels.SortedPairs -}}
                  {{- if ne .Name "alertname" -}}
                      {{- .Name }}%3D%22{{- reReplaceAll " +" "%20" .Value -}}%22%2C%20
                  {{- end -}}
              {{- end -}}
              alertname%3D%22{{ reReplaceAll " +" "%20" .CommonLabels.alertname }}%22%7D
            |||,
          ),
        ],
      },
    ],
  };

local WebhookReceiver(channel) = {
  name: channel.name,
  webhook_configs: [
    {
      url: channel.url,
      send_resolved: channel.sendResolved,
      http_config: if std.objectHas(channel, 'httpConfig') then channel.httpConfig else {},
    },
  ],
};

//
// Route helpers and definitions.

// Returns a list of teams with valid `slack_alerts_channel` values
local teamsWithAlertingSlackChannels() =
  local allTeams = serviceCatalog.getTeams();
  std.filter(function(team) std.objectHas(team, 'slack_alerts_channel') && team.slack_alerts_channel != '', allTeams);

// Returns a list of stage group teams wiht slack channels for alerting
local teamsWithProductStageGroups() =
  std.filter(
    function(team) std.objectHas(team, 'product_stage_group'),
    teamsWithAlertingSlackChannels()
  );

local defaultGroupBy = [
  'env',
  'tier',
  'type',
  'alertname',
  'stage',
  'component',
];

local Route(
  receiver,
  match=null,
  match_re=null,
  group_by=null,
  group_wait=null,
  group_interval=null,
  repeat_interval=null,
  continue=null,
  routes=null,
      ) = {
  receiver: receiver,
  [if match != null then 'match']: match,
  [if match_re != null then 'match_re']: match_re,
  [if group_by != null then 'group_by']: group_by,
  [if group_wait != null then 'group_wait']: group_wait,
  [if group_interval != null then 'group_interval']: group_interval,
  [if repeat_interval != null then 'repeat_interval']: repeat_interval,
  [if routes != null then 'routes']: routes,
  [if continue != null then 'continue']: continue,
};

local RouteCase(
  match=null,
  match_re=null,
  group_by=null,
  group_wait=null,
  group_interval=null,
  repeat_interval=null,
  continue=true,
  defaultReceiver=null,
  when=null,
      ) =
  Route(
    receiver=defaultReceiver,
    match=match,
    match_re=match_re,
    group_by=group_by,
    group_wait=group_wait,
    group_interval=group_interval,
    repeat_interval=repeat_interval,
    continue=continue,
    routes=[
      (
        local c = { match: null, match_re: null } + case;
        Route(
          receiver=c.receiver,
          match=c.match,
          match_re=c.match_re,
          group_by=null,
          continue=false
        )
      )
      for case in when
    ],
  );

local SnitchRoute(channel) =
  Route(
    receiver=SnitchReceiver(channel),
    match={
      alertname: 'SnitchHeartBeat',
      cluster: channel.cluster,
      env: channel.name,
    },
    group_by=null,
    group_wait='1m',
    group_interval='5m',
    repeat_interval='5m',
    continue=false
  );

local receiverNameForTeamSlackChannel(team) =
  'team_' + std.strReplace(team.name, '-', '_') + '_alerts_channel';

local routingTree = Route(
  continue=null,
  group_by=defaultGroupBy,
  repeat_interval='8h',
  receiver='prod_alerts_slack_channel',
  routes=
  [
    /* SnitchRoutes do not continue */
    SnitchRoute(channel)
    for channel in secrets.snitchChannels
  ] +
  [
    /* issue alerts do continue */
    Route(
      receiver='issue:' + issueChannel.name,
      match={
        env: env,
        incident_project: issueChannel.name,
      },
      continue=true,
      group_wait='10m',
      group_interval='1h',
      repeat_interval='3d',
    )
    for issueChannel in secrets.issueChannels
    for env in ['gprd', 'ops']
  ] + [
    /* pager=pagerduty alerts do continue */
    RouteCase(
      match={ pager: 'pagerduty' },
      match_re={ env: 'gprd|ops' },
      continue=true,
      /* must be less than the 6h auto-resolve in PagerDuty */
      repeat_interval='2h',
      when=[
        { match: { slo_alert: 'yes', env: 'gprd', stage: 'cny' }, receiver: 'slo_gprd_cny' },
        { match: { slo_alert: 'yes', env: 'gprd', stage: 'main' }, receiver: 'slo_gprd_main' },
        { match: { slo_alert: 'yes', env: 'gprd', stage: 'main' }, receiver: 'slo_gprd_main' },
      ],
      defaultReceiver='prod_pagerduty',
    ),
    /*
     * Send ops/gprd slackline alerts to production slackline
     * gstg slackline alerts go to staging slackline
     * other slackline alerts are passed up
     */
    Route(
      receiver='slack_bridge-prod',
      match={ rules_domain: 'general', env: 'gprd' },
      continue=true,
      // rules_domain='general' should be preaggregated so no need for additional groupBy keys
      group_by=['...']
    ),
    Route(
      receiver='slack_bridge-prod',
      match={ rules_domain: 'general', env: 'ops' },
      continue=true,
      // rules_domain='general' should be preaggregated so no need for additional groupBy keys
      group_by=['...']
    ),
    Route(
      receiver='slack_bridge-nonprod',
      match={ rules_domain: 'general', env: 'gstg' },
      continue=true,
      // rules_domain='general' should be preaggregated so no need for additional groupBy keys
      group_by=['...']
    ),
  ] + [
    Route(
      receiver=receiverNameForTeamSlackChannel(team),
      continue=true,
      match={
        env: 'gprd',  // For now we only send production channel alerts to teams
        product_stage_group: team.name,
      },
    )
    for team in teamsWithProductStageGroups()
  ] + [
    Route(
      receiver=receiverNameForTeamSlackChannel(team),
      continue=true,
      match={
        env: 'gprd',  // For now we only send production channel alerts to teams
        team: team.name,
      },
    )
    for team in teamsWithAlertingSlackChannels()
  ] + [
    // Terminators go last
    Route(
      receiver='blackhole',
      match={ env: 'pre' },
      continue=false,
    ),
    Route(
      receiver='blackhole',
      match={ env: 'dr' },
      continue=false,
    ),
    Route(
      receiver='blackhole',
      match={ env: 'gstg' },
      continue=false,
    ),
    // Pager alerts should appear in the production channel
    Route(
      receiver='production_slack_channel',
      match={ pager: 'pagerduty' },
      continue=false,
    ),
    // All else to #alerts
    Route(
      receiver='prod_alerts_slack_channel',
      continue=false,
    ),
  ]
);


// Recursively walk a tree, adding all receiver names
local findAllReceiversInRoutingTree(tree, currentReceiverNamesSet) =
  local receiverNameSet = std.setUnion(currentReceiverNamesSet, [tree.receiver]);
  if std.objectHas(tree, 'routes') then
    std.foldl(function(memo, route) findAllReceiversInRoutingTree(route, memo), tree.routes, receiverNameSet)
  else
    receiverNameSet;

// Trim unused receivers to avoid warning messages from alertmanager
local pruneReceivers(receivers, routingTree) =
  local allReceivers = findAllReceiversInRoutingTree(routingTree, []);
  std.filter(function(r) std.setMember(r.name, allReceivers), receivers);

//
// Generate the list of routes and receivers.

local receivers =
  [PagerDutyReceiver(c) for c in secrets.pagerDutyChannels] +
  [SlackReceiver(c) for c in slackChannels] +

  // Generate receivers for each team that has a channel
  [SlackReceiver({
    name: receiverNameForTeamSlackChannel(team),
    channel: team.slack_alerts_channel,
  }) for team in teamsWithAlertingSlackChannels()] +
  [WebhookReceiver(c) for c in webhookChannels] +
  [
    // receiver that does nothing with the alert, blackholing it
    {
      name: 'blackhole',
    },
  ];

//
// Generate the whole alertmanager config.
local alertmanager = {
  global: {
    slack_api_url: secrets.slackAPIURL,
  },
  receivers: pruneReceivers(receivers, routingTree),
  route: routingTree,
  templates: [
    templateDir + '/*.tmpl',
  ],
};

local k8sAlertmanagerSecret = {
  apiVersion: 'v1',
  kind: 'Secret',
  metadata: {
    name: 'alertmanager-config',
    namespace: 'monitoring',
  },
  data: {
    'alertmanager.yaml': std.base64(std.manifestYamlDoc(alertmanager)),
    'gitlab.tmpl': std.base64(importstr 'templates/gitlab.tmpl'),
    'slack.tmpl': std.base64(importstr 'templates/slack.tmpl'),
  },
};

{
  'alertmanager.yml': std.manifestYamlDoc(alertmanager, indent_array_in_object=true),
  'k8s_alertmanager_secret.yaml': std.manifestYamlDoc(k8sAlertmanagerSecret, indent_array_in_object=true),
}
