# Redis troubleshooting

## First and foremost

*Don't Panic*

## Replication issues

See [redis_replication.md].


## Failed to collect Redis metrics

### Symptoms

You see alerts like `FailedToGetRedisMetrics`.

### Possible checks

#### Checks Using Prometheus

https://thanos-query.ops.gitlab.net/graph?g0.range_input=1w&g0.expr=redis_up%20%3C%201&g0.tab=0

#### Check on host

`gitlab-ctl status`

`telnet localhost:6379`

If everything looks ok, it might be that the instance made a full resync from
master. During that time the redis_exporter fails to collect metrics from
redis. Check `/var/log/gitlab/redis/current` for `MASTER <-> SLAVE sync`
events.

### Solution

If either of the `redis` or `sentinel` services is down, restart it with

`gitlab-ctl restart redis`

or

`gitlab-ctl restart sentinel`.

Else check in the redis logs for possible issues (e.g. resync from master).

