// GET-hybrid deployments contain no sidekiq shards, but the configuration is left to keep the compatibility to
// environments with multiple shards
local shards = {
  catchall: { urgency: null, gkeDeployment: 'not-applicable', userImpacting: true, ignoreTrafficCessation: false /* no urgency attribute since multiple values are supported */ },
};

// These values are used in several places, so best to DRY them up
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

    listAll():: std.map(function(name) shards[name] { name: name }, std.objectFields(shards)),

    // List shards which match on the supplied predicate
    listFiltered(filterPredicate): std.filter(function(f) filterPredicate({ autoScaling: true } + shards[f]), std.objectFields(shards)),
  },
}
