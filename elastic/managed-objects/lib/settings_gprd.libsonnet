local VERY_HIGH_THROUGHPUT = ['gitaly', 'rails', 'workhorse'];
local HIGH_THROUGHPUT = ['sidekiq', 'shell', 'puma', 'monitoring', 'registry', 'system'];
local MEDIUM_THROUGHPUT = ['gke-audit', 'pages', 'fluentd', 'postgres', 'runner'];

local setting(index, env) = if std.member(VERY_HIGH_THROUGHPUT, index) then {
  index: {
    codec: 'best_compression',
    lifecycle: {
      name: 'gitlab-infra-high-ilm-policy',
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
        total_shards_per_node: 1,
      },
    },
    search: {
      idle: {
        after: '30s',
      },
      slowlog: {
        threshold: {
          query: {
            warn: '30s',
            info: '30s',
            debug: '-1',
            trace: '-1',
          },
          fetch: {
            warn: '30s',
            info: '30s',
            debug: '-1',
            trace: '-1',
          },
        },
      },
    },
    refresh_interval: '10s',  // see: https://gitlab.com/gitlab-com/gl-infra/production/-/issues/3006#note_445081437
  },
  number_of_shards: 15,
  // number_of_replicas: 1,
}
else if std.member(HIGH_THROUGHPUT, index) then {
  index: {
    codec: 'best_compression',
    lifecycle: {
      name: 'gitlab-infra-high-ilm-policy',
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
        total_shards_per_node: 1,
      },
    },
    search: {
      idle: {
        after: '30s',
      },
      slowlog: {
        threshold: {
          query: {
            warn: '30s',
            info: '30s',
            debug: '30s',
            trace: '30s',
          },
          fetch: {
            warn: '30s',
            info: '30s',
            debug: '30s',
            trace: '30s',
          },
        },
      },
    },
    refresh_interval: '30s',  // see: https://gitlab.com/gitlab-com/gl-infra/production/-/issues/3006#note_445081437
  },
  number_of_shards: 12,
  // number_of_replicas: 1,
}
else if std.member(MEDIUM_THROUGHPUT, index) then {
  index: {
    codec: 'best_compression',
    lifecycle: {
      name: 'gitlab-infra-medium-ilm-policy',
      rollover_alias: 'pubsub-%s-inf-%s' % [index, env],
    },
    mapping: {
      ignore_malformed: true,
    },
    routing: {
      allocation: {
        total_shards_per_node: 1,
      },
    },
    search: {
      idle: {
        after: '30s',
      },
      slowlog: {
        threshold: {
          query: {
            warn: '30s',
            info: '30s',
            debug: '30s',
            trace: '30s',
          },
          fetch: {
            warn: '30s',
            info: '30s',
            debug: '30s',
            trace: '30s',
          },
        },
      },
    },
    refresh_interval: '30s',
  },
  number_of_shards: 3,
  // number_of_replicas: 1,
} else {
  index: {
    codec: 'best_compression',
    lifecycle: {
      name: 'gitlab-infra-default-ilm-policy',
      rollover_alias: 'pubsub-%s-inf-%s' % [index, env],
    },
    mapping: {
      ignore_malformed: true,
    },
    search: {
      idle: {
        after: '30s',
      },
      slowlog: {
        threshold: {
          query: {
            warn: '30s',
            info: '30s',
            debug: '30s',
            trace: '30s',
          },
          fetch: {
            warn: '30s',
            info: '30s',
            debug: '30s',
            trace: '30s',
          },
        },
      },
    },
    refresh_interval: '30s',
  },
  // number_of_shards: 1,
  // number_of_replicas: 1,
};

{
  setting:: setting,
}
