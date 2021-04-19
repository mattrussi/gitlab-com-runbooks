# Summary

When we see an SQL Apdex alert is important to quickly asses the impact and rule out common causes like abuse and identify problematic queries.
This runbook covers some of the topics that were discussed in the [EOC Firedrill](https://docs.google.com/document/d/1WiHy60tedoZnjKs8ypceHVu8p-E0-6wXZkzFb02P4CY/edit#heading=h.39dmlgcxc042).

## What to do in the first 5 minutes

- Be aware of the [primary database](https://dashboards.gitlab.net/d/000000244/postgresql-replication-overview?orgId=1) for log queries
- Check the dashboards and log links below to asses root cause
- See if there is a quick recovery, if not page the IMOC who will bring in the CMOC in case we need to make a status page update

### Dashboards

- Check the [GitLab general overview](https://dashboards.gitlab.com/d/general-public-splashscreen/general-gitlab-dashboards?orgId=1&from=now-30m&to=now) for service degradation
- Check the [Patroni overview](https://dashboards.gitlab.net/d/patroni-main/patroni-overview?orgId=1&from=now-1h&to=now&var-PROMETHEUS_DS=Global&var-environment=gprd) for the current status of Patroni.
- Look for unusual usage patterns in [tuple statistics](https://dashboards.gitlab.net/d/000000167/postgresql-tuple-statistics?orgId=1&refresh=1m)
- Look for outliers in the [marginalia sampler dashboard](https://dashboards.gitlab.net/d/patroni-marginalia-sampler/patroni-marginalia-sampler?orgId=1&from=now-1h&to=now&var-PROMETHEUS_DS=Global&var-environment=gprd&var-fqdn=patroni-03-db-gprd.c.gitlab-production.internal&var-application=All&var-endpoint=All&var-state=All&var-wait_event_type=All)

### Logs

- [Primary queries by endpoint_id if it exists](https://log.gprd.gitlab.net/goto/1aee2b0cd35ffb9b14c82e5b09237392)
    - Grab the first `endpoint_id`, search [the logs](https://log.gprd.gitlab.net/goto/07606a8985e78fa0a4f83e07f043c7d5) by setting  `json.meta.caller_id` to the `endpoint_id` and try to find a common denominator, for example, `json.meta.root_namespace`.
- [Slow queries on the primary](https://log.gprd.gitlab.net/goto/7648f3995aa30dd1681fd9f4af2c13c0)
- [Statement timeouts on the primary](https://log.gprd.gitlab.net/goto/6744c482baeb5494fd2ce124d08b9e82)
- [Locks on the primary](https://log.gprd.gitlab.net/goto/20db7e839d10534b9c47fa1149898e21)
- [Check for unusual stats for a specific relname](https://prometheus-db.gprd.gitlab.net/graph?g0.expr=(sum%20by(environment%2C%20tier%2C%20type%2C%20relname)%20(rate(pg_stat_user_tables_idx_tup_fetch%7Btype%3D%22patroni%22%7D%5B5m%5D)%20and%20on(job%2C%20instance)%20pg_replication_is_replica%20%3D%3D%201)%20%2F%20ignoring(relname)%20group_left()%20sum%20by(environment%2C%20tier%2C%20type)%20(rate(pg_stat_user_tables_idx_tup_fetch%7Btype%3D%22patroni%22%7D%5B5m%5D)%20and%20on(job%2C%20instance)%20pg_replication_is_replica%20%3D%3D%201))%20%3E%200.5&g0.tab=0&g0.stacked=0&g0.range_input=2h)

_For any of the above queries, you can search for json.fingerprint on the left list of fields, click on it to see if a particular fingerprint is dominating slow queries or timeouts. From this, you can get the full query (or the endpoint ID) which will help to narrow down the performance degradation_

For more detailed information about slow queries, see the [runbook for collecting pg data](https://gitlab.com/gitlab-com/runbooks/-/blob/master/docs/patroni/pg_collect_query_data.md)

### Abuse

Often abuse can be the source of DB degradation, to see if there might be abuse happening reference the [abuse runbook](https://gitlab.com/gitlab-com/runbooks/-/blob/master/docs/ci-runners/ci-abuse-handling.md)
