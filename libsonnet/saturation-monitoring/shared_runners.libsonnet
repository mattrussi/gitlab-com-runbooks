local selectors = import 'promql/selectors.libsonnet';
local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local resourceSaturationPoint = metricsCatalog.resourceSaturationPoint;

local baseSelector = { job: 'runners-manager' };
local serviceStaticLabels = {
  type: 'ci-runners',
  tier: 'runners',
  stage: 'main',
};
local defaultSlos = {
  soft: 0.90,
  hard: 0.95,
};

local runnersSaturationPoint(selector, title, staticLabels=serviceStaticLabels, slos=defaultSlos) = resourceSaturationPoint({
  title: '%s Runner utilization' % [title],
  severity: 's4',
  horizontallyScalable: true,
  appliesTo: ['ci-runners'],
  description: |||
    %s runner utilization per instance.

    Each runner manager has a maximum number of runners that it can coordinate at any single moment.

    When this metric is saturated, new CI jobs will queue. When this occurs we should consider adding more runner managers,
    or scaling the runner managers vertically and increasing their maximum runner capacity.
  ||| % [title],
  grafana_dashboard_uid: 'sat_%s_runners' % [std.asciiLower(std.strReplace(title, ' ', '_'))],
  resourceLabels: ['instance', 'shard'],
  staticLabels: staticLabels,
  query: |||
    sum without(executor_stage, exported_stage, state) (
      max_over_time(gitlab_runner_jobs{job="runners-manager",%(runnerSelector)s}[%(rangeInterval)s])
    )
    /
    gitlab_runner_limit{job="runners-manager",%(runnerSelector)s} > 0
  |||,
  queryFormatConfig: {
    runnerSelector: selectors.serializeHash(selector),
  },
  slos: slos,
});

{
  private_runners: runnersSaturationPoint(
    { shard: 'private' },
    'Private',
    slos=defaultSlos { soft: 0.85 },
  ),
  // Excluding windows-shared & macos-shared, those are currently fully saturated with a limit of 0
  shared_runners: runnersSaturationPoint({ shard: { noneOf: ['private', 'shared-gitlab-org', 'windows-shared', 'macos-shared'] } }, 'Shared'),
  shared_runners_gitlab: runnersSaturationPoint(
    { shard: 'shared-gitlab-org' },
    'Shared GitLab',
    staticLabels={},  // No static labels here to not include it on the service dashboard
  ),
}
