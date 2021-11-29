{
  "trigger": {
    "schedule": {
      "interval": "5m"
    }
  },
  "input": {
    "search": {
      "request": {
        "search_type": "query_then_fetch",
        "indices": [
          "pubsub-rails-inf-gstg*",
          "pubsub-sidekiq-inf-gstg*"
        ],
        "rest_total_hits_as_int": true,
        "body": {
          "query": {
            "bool": {
              "must": [
                {
                  "range": {
                    "@timestamp": {
                      "gte": "now-7m",
                      "lte": "now"
                    }
                  }
                },
                {
                  "bool": {
                    "minimum_should_match": 1,
                    "should": [
                      {
                        "bool": {
                          "must": {
                            "match_phrase": {
                              "json.exception.class": "NoMethodError"
                            }
                          },
                          "must_not": {
                            "match_phrase": {
                              "json.exception.message": "\"nil:NilClass\""
                            }
                          }
                        }
                      },
                      {
                        "bool": {
                          "must": {
                            "match_phrase": {
                              "json.error_class": "NoMethodError"
                            }
                          },
                          "must_not": {
                            "match_phrase": {
                              "json.error_message": "\"nil:NilClass\""
                            }
                          }
                        }
                      }
                    ]
                  }
                }
              ]
            }
          },
          "size": 0
        }
      }
    }
  },
  "condition": {
    "compare": {
      "ctx.payload.hits.total": {
        "gt": 0
      }
    }
  },
  "actions": {
    "notify-slack": {
      "throttle_period_in_millis": 420000,
      "slack": {
        "message": {
          "from": "ElasticCloud Watcher: NoMethodError",
          "to": [
            "#staging"
          ],
          "text": "NoMethodError: {{ctx.payload.hits.total}} errors detected! Please investigate"
        }
      }
    }
  }
}
