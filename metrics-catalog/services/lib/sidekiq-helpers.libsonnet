// Sidekiq Shard Definitions
// This should contain a list of sidekiq shards
local shardDefaults = {
  autoScaling: true,
};

local shardDefinitions = {
  'database-throttled': { urgency: 'throttled', gkeDeployment: 'gitlab-sidekiq-database-throttled-v2' },
  'gitaly-throttled': { urgency: 'throttled', gkeDeployment: 'gitlab-sidekiq-gitaly-throttled-v2' },
  'low-urgency-cpu-bound': { urgency: 'low', gkeDeployment: 'gitlab-sidekiq-low-urgency-cpu-bound-v2' },
  'memory-bound': { urgency: null, gkeDeployment: 'gitlab-sidekiq-memory-bound-v2' },
  quarantine: { urgency: null, gkeDeployment: 'gitlab-sidekiq-catchall-v2' },
  'urgent-cpu-bound': { urgency: 'high', gkeDeployment: 'gitlab-sidekiq-urgent-cpu-bound-v2' },
  'urgent-other': { urgency: 'high', autoScaling: false, gkeDeployment: 'gitlab-sidekiq-urgent-other-v2' },
  'urgent-authorized-projects': { urgency: 'throttled', gkeDeployment: 'gitlab-sidekiq-urgent-authorized-projects-v2' },
  catchall: { urgency: null, gkeDeployment: 'gitlab-sidekiq-catchall-v2' },
  elasticsearch: { urgency: 'throttled', gkeDeployment: 'gitlab-sidekiq-elasticsearch-v2' },
};

local shards = std.foldl(
  function(memo, shardName)
    memo { [shardName]: shardDefaults + shardDefinitions[shardName] { name: shardName } },
  std.objectFields(shardDefinitions),
  {}
);
// These values are used in several places, so best to DRY them up
// These should be kept in sync with https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/metrics/sidekiq_slis.rb
{
  slos: {
    urgent: {
      queueingDurationSeconds: 10,
      executionDurationSeconds: 10,
    },
    lowUrgency: {
      queueingDurationSeconds: 60,
      executionDurationSeconds: 300,
    },
    throttled: {
      // Throttled jobs don't have a queuing duration,
      // so don't add one here!
      executionDurationSeconds: 300,
    },
  },
  shards: {
    listByName():: std.objectFields(shards),

    listAll():: std.objectValues(shards),

    // List shards which match on the supplied predicate
    listFiltered(filterPredicate): std.filter(function(f) filterPredicate(shards[f]), std.objectFields(shards)),
  },
}
