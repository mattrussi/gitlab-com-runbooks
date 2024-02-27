// Watcher for notifying that a table should have been locked
// Fixes https://gitlab.com/gitlab-org/gitlab/-/issues/413654
local schedule_mins = 60;  // Run this watch every hour
local query_period = schedule_mins * 24; // Look back 24 hours

// Using this a variant of query:
// https://log.gprd.gitlab.net/app/r/s/sKIEo
local es_query = {
  search_type: 'query_then_fetch',
  indices: [
    'pubsub-sidekiq-inf-gprd*'
  ],
  body: {
    query: {
      bool: {
        must: [
          {
            range: {
              '@timestamp': { gte: std.format('now-%dm', query_period), lte: 'now' },
            },
          },
          {
            bool: {
              should: [
                {
                  term: {
                    "json.class.keyword": {
                      "value": "Database::MonitorLockedTablesWorker"
                    }
                  }
                }
              ],
              minimum_should_match: 1
            }
          },
          {
            bool: {
              should: [
                {
                  match_phrase: {
                    "json.job_status": "done"
                  }
                }
              ],
              minimum_should_match: 1
            }
          },
          {
            bool: {
              should: [
                {
                  bool: {
                    should: [
                      {
                        range: {
                          "json.extra.database_monitor_locked_tables_worker.results.ci.tables_need_lock_count": {
                            "gt": "0"
                          }
                        }
                      }
                    ],
                    minimum_should_match: 1
                  }
                },
                {
                  bool: {
                    should: [
                      {
                        range: {
                          "json.extra.database_monitor_locked_tables_worker.results.main.tables_need_lock_count": {
                            "gt": "0"
                          }
                        }
                      }
                    ],
                    minimum_should_match: 1
                  }
                }
              ],
              minimum_should_match: 1
            }
          }
        ],
      }
    }
  }
};

{
  trigger: {
    schedule: {
      interval: std.format('%dm', schedule_mins),
    },
  },
  input: {
    search: {
      request: es_query,
    },
  },
  condition: {
    compare: {
      'ctx.payload.hits.total': {
        gt: 0,
      },
    },
  },
  actions: {
    'notify-slack': {
      throttle_period: query_period + 'm',
      slack: {
        message: {
          from: 'ElasticCloud Watcher: Database::MonitorLockedTablesWorker could not lock all tables',
          to: [
            '#g_tenant-scale'
          ],
          text: 'Database::MonitorLockedTablesWorker could not lock all tables. Logs: https://log.gprd.gitlab.net/app/r/s/508tx . Please investigate why locking the reported tables failed.',
        },
      },
    },
  },
}
