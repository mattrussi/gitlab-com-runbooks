local HIGH_THROUHGPUT = ['gitaly', 'rails', 'workhorse', 'sidekiq'];
local MEDIUM_THROUGHPUT = ['gke', 'shell', 'system', 'sentry', 'vault', 'mimir'];

local setting(index, env) = if std.member(HIGH_THROUHGPUT, index) then {
  index: {
    codec: 'best_compression',
    lifecycle: {
      name: 'gitlab-infra-ilm-policy',
      rollover_alias: 'pubsub-%s-inf-%s' % [index, env],
    },
    mapping: {
      ignore_malformed: true,
      total_fields: {
        limit: 10000,
      },
    },
    routing: {
      allocation: {
        total_shards_per_node: 2,
      },
    },
    search: {
      idle: {
        after: '30s',
      },
    },
    refresh_interval: '10s',
  },
  number_of_shards: 2,
  // number_of_replicas: 1,
}
else if std.member(MEDIUM_THROUGHPUT, index) then {
  index: {
    codec: 'best_compression',
    lifecycle: {
      name: 'gitlab-infra-ilm-policy',
      rollover_alias: 'pubsub-%s-inf-%s' % [index, env],
    },
    mapping: {
      ignore_malformed: true,
    },
    search: {
      idle: {
        after: '30s',
      },
    },
    refresh_interval: '10s',
  },
  // number_of_shards: 1,
  // number_of_replicas: 1,
} else {
  index: {
    codec: 'best_compression',
    lifecycle: {
      name: 'gitlab-infra-ilm-policy',
      rollover_alias: 'pubsub-%s-inf-%s' % [index, env],
    },
    mapping: {
      ignore_malformed: true,
    },
    search: {
      idle: {
        after: '30s',
      },
    },
    refresh_interval: '10s',
  },
  // number_of_shards: 1,
  // number_of_replicas: 1,
};

{
  setting:: setting,
}
