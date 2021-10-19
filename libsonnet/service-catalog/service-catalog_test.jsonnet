local test = import 'github.com/yugui/jsonnetunit/jsonnetunit/test.libsonnet';
local serviceCatalog = import 'service-catalog/service-catalog.libsonnet';

local services = [
  {
    type: 'api',
    serviceDependencies: {
      gitaly: true,
      'redis-tracechunks': true,
      'redis-sidekiq': true,
      'redis-cache': true,
      redis: true,
    },
  },
  {
    type: 'gitaly',
    serviceDependencies: {
      gitaly: true,
    },
  },
  {
    type: 'frontend',
    serviceDependencies: {
      api: true,
    },
  },
  {
    type: 'web',
    serviceDependencies: {
      redis: true,
      gitaly: true,
    },
  },
  {
    type: 'pages',
    serviceDependencies: {
      pgbouncer: true,
    },
  },
  {
    type: 'pgbouncer',
    serviceDependencies: {
      patroni: true,
    },
  },
  { type: 'woodhouse' },
  { type: 'patroni' },
  { type: 'redis' },
  { type: 'redis-tracechunks' },
  { type: 'redis-cache' },
  { type: 'redis-sidekiq' },
];

test.suite({
  testBlank: {
    actual: serviceCatalog.buildServiceGraph(services),
    expect: {
      api: { inward: ['frontend'], outward: ['gitaly', 'redis', 'redis-cache', 'redis-sidekiq', 'redis-tracechunks'] },
      frontend: { inward: [], outward: ['api'] },
      gitaly: { inward: ['web', 'api'], outward: [] },  //  It does not include self-reference
      pages: { inward: [], outward: ['pgbouncer'] },
      patroni: { inward: ['pgbouncer'], outward: [] },
      pgbouncer: { inward: ['pages'], outward: ['patroni'] },
      redis: { inward: ['web', 'api'], outward: [] },
      'redis-cache': { inward: ['api'], outward: [] },
      'redis-sidekiq': { inward: ['api'], outward: [] },
      'redis-tracechunks': { inward: ['api'], outward: [] },
      web: { inward: [], outward: ['gitaly', 'redis'] },
      woodhouse: { inward: [], outward: [] },  // forever alone
    },
  },
  testGetTeam: {
    actual: serviceCatalog.getTeam('sre_coreinfra'),
    expect: {
      name: 'sre_coreinfra',
      url: 'https://about.gitlab.com/handbook/engineering/infrastructure/team/reliability/#core-infra',
      slack_channel: 'sre_coreinfra',
      engagement_policy: null,
      oncall_schedule: 'https://gitlab.pagerduty.com/schedules#P22HQSG',
      issue_tracker: null,
      send_slo_alerts_to_team_slack_channel: false,
    },
  },
  testTeams: {
    // Filtering in order not to have a test that fails every time someone adds
    // a team
    actual: std.set(
      std.filterMap(
        function(team) team.name == 'sre_coreinfra' || team.name == 'scalability',
        function(team) team.name,
        serviceCatalog.getTeams()
      )
    ),
    expect: std.set(['sre_coreinfra', 'scalability']),
  },
  testLookupExistingTeamForStageGroup: {
    actual: serviceCatalog.lookupTeamForStageGroup('access'),
    expect: {
      issue_tracker: null,
      name: 'access',
      product_stage_group: 'access',
      send_slo_alerts_to_team_slack_channel: true,
      slack_alerts_channel: 'feed_alerts_access',
    },
    testLookupNonExistingTeamForStageGroup: {
      actual: serviceCatalog.lookupTeamForStageGroup('huzzah'),
      expect: {},
    },
  },
})
