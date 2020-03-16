### Pre-check

1. [ ] Run all the steps on staging
1. [ ] Run a dry run process in production where all we do is reindex the data to the Destination Cluster

### Process

1. [ ] Create a new Elasticsearch cluster referred to as Destination Cluster. We will refer to the existing cluster as Source Cluster throughout the rest of the steps.
1. [ ] Let SRE on call know that we are triggering the re-index in #production: `@sre-oncall please note we are doing a reindex of our production Elasticsearch cluster which will re-index all of our production global search cluster to another Elasticsearch cluster using the Elasticsearch reindex API. This will increase search load on the production cluster but should not impact any other systems. <LINK>`
1. [ ] Disable search with Elasticsearch in `GitLab > Admin > Settings > Integrations`
1. [ ] Pause indexing writes (stop Elasticsearch sidekiq node): `sudo gitlab-ctl stop sidekiq-cluster`
1. [ ] Note the size of the source cluster `gitlab-production` index: `<XX> GB`
1. [ ] Trigger re-index from source cluster to destination cluster `gitlab-rake gitlab:elastic:reindex_to_another_cluster[$SOURCE_CLUSTER_URL,$DESTINATION_CLUSTER_URL,6000]` (these are the full URL including the basic auth credentials as entered via the GitLab admin)
1. [ ] Note the returned [task ID](https://www.elastic.co/guide/en/elasticsearch/reference/current/tasks.html) from the above: `<TASK_ID>`
1. [ ] Note the time when the task started: `<TASK_STARTED_TIME>`
1. [ ] Track the progress of reindexing using the Tasks API `curl $DESTINATION_CLUSTER_URL/_tasks/$TASK_ID`
1. [ ] Note the time when the task finishes: `<TASK_FINISHED_TIME>`
1. [ ] Note the total time taken to reindex: `<TIME_TAKEN_TO_REINDEX>`
1. [ ] Change the `refresh_interval` setting on Destination Cluster to `60`
   - [ ] `curl -XPUT -d '{"index":{"refresh_interval":"60s"}}' -H 'Content-Type: application/json' "$DESTINATION_CLUSTER_URL/gitlab-production/_settings"`
1. [ ] Verify `number of documents in Destination Cluster gitlab-production index` = `number of documents in Source Cluster gitlab-production index`
   - [ ] Be aware it may take 60s to refresh on the destination cluster
   - [ ] `curl $SOURCE_CLUSTER_URL/gitlab-production/_count` => `<COUNT>`
   - [ ] `curl $DESTINATION_CLUSTER_URL/gitlab-production/_count` => `<COUNT>`
1. [ ] Increase replication on Destination Cluster to `1`:
   - [ ] `curl -XPUT -d '{"index":{"number_of_replicas":"1"}}' -H 'Content-Type: application/json' "$DESTINATION_CLUSTER_URL/gitlab-production/_settings"`
1. [ ] Wait for cluster monitoring to show the replication has completed
1. [ ] Note the size of the destination cluster `gitlab-production` index: `<XX> GB`
1. [ ] Update the durability to the default value
   - [ ] `curl -XPUT -d '{"index":{"translog":{"durability":"request"}}}' -H 'Content-Type: application/json' "$DESTINATION_CLUSTER_URL/gitlab-production/_settings"`
1. [ ] Change settings in `GitLab > Admin > Settings > Integrations` to point to Destination Cluster
1. [ ] Re-enable indexing writes (start Elasticsearch sidekiq node) `sudo gitlab-ctl start sidekiq-cluster`
1. [ ] Wait until the backlog of incremental updates gets below 1000
   - Chart `Global search incremental indexing queue depth` https://dashboards.gitlab.net/d/sidekiq-main/sidekiq-overview?orgId=1
1. [ ] Enable search with Elasticsearch in `GitLab > Admin > Settings > Integrations`
1. [ ] Create a comment somewhere then search for it to ensure indexing still works (can take a minute to catch up)
   1. [ ] Confirm it's caught up by checking [Global search incremental indexing queue depth
](https://dashboards.gitlab.net/d/sidekiq-main/sidekiq-overview?orgId=1) or the source of truth via rails console: `Elastic::ProcessBookkeepingService.queue_size`

## Rollback steps

1. [ ] Switch GitLab settings to point back to Source Cluster
1. [ ] Ensure any updates that only went to Destination Cluster are replayed
   against Source Cluster by searching the logs for the updates
   https://gitlab.com/gitlab-org/gitlab/-/blob/e8e2c02a6dbd486fa4214cb8183d428102dc1156/ee/app/services/elastic/process_bookkeeping_service.rb#L23
   and triggering those updates again using
   [`ProcessBookkeepingService#track`](https://gitlab.com/gitlab-org/gitlab/-/blob/153bd30359eeaeb9803fcac9535d1b6d4aef1e19/ee/app/services/elastic/process_bookkeeping_service.rb#L12)
