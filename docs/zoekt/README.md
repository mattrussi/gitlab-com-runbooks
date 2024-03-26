<!-- MARKER: do not edit this section directly. Edit services/service-catalog.yml then run scripts/generate-docs -->

**Table of Contents**

[[_TOC_]]

# Global Code Search Service

* **Alerts**: <https://alerts.gitlab.net/#/alerts?filter=%7Btype%3D%22zoekt%22%2C%20tier%3D%22inf%22%7D>
* **Label**: gitlab-com/gl-infra/production~"Service::Zoekt"

## Logging

* [Rails](https://log.gprd.gitlab.net/goto/15b83f5a97e93af2496072d4aa53105f)
* [Sidekiq](https://log.gprd.gitlab.net/goto/d7e4791e63d2a2b192514ac821c9f14f)

<!-- END_MARKER -->

## Summary

### Quick start

Currently we use Elasticsearch for code search within GitLab. Elasticsearch has turned out to be a poor fit for code search.
In order to solve that we're rolling out new Code Search based on [Zoekt](https://github.com/sourcegraph/zoekt) to select
number of customers as part of this [epic](https://gitlab.com/groups/gitlab-org/-/epics/9404).

### How-to guides

#### Enabling/Disabling Zoekt search

You can prevent Gitlab from using Zoekt integration for searching, but leave the indexing integration itself enabled. An example of when this is useful is during an incident where users are experiencing slow searches or Zoekt is unresponsive.

* [`search_code_with_zoekt`](https://gitlab.com/gitlab-org/gitlab/blob/master/ee/config/feature_flags/development/search_code_with_zoekt.yml)

#### Removing namespaces from the zoekt node

If Zoekt search FF is disabled, but you still see that some nodes misbehave (OOM for example),
you can evict some of the namespaces from the node:

1. Execute the script in rails console

   ```ruby
   # Find the offending node (gitlab-gitlab-zoekt-1 in this example)
   node = Search::Zoekt::Node.where("metadata @> ?", { name: 'gitlab-gitlab-zoekt-1' }.to_json).order(:last_seen_at).last

   # Load indexed namespaces
   node.indexed_namespaces.map{ |n| n.attributes.slice('id', 'namespace_id', 'search') }
   ```

1. Pick the largest ones (you can use `/chatops run namespace find <NAMESPACE_ID>` to get the namespace size)
1. Destroy these `Zoekt::IndexedNamespace` records

   ```
   zoekt_indexed_namespace_ids = [1000072, 1000073]
   node.indexed_namespaces.where(id: zoekt_indexed_namespace_ids).destroy_all
   ```

1. Post namespace_ids on the incident issue as a private comment so that we can add these back later

#### Pausing Zoekt indexing

Zoekt indexing can be paused. The [jobs are stored in a separate `ZSET`](https://docs.gitlab.com/ee/development/sidekiq/worker_attributes.html#job-pause-control) and re-enqueued when indexing is unpaused. An example
of when this is useful is during an incident when there are a large number of indexing Sidekiq jobs failing.

* [`zoekt_pause_indexing`](https://gitlab.com/gitlab-org/gitlab/blob/master/ee/config/feature_flags/ops/zoekt_pause_indexing.yml)

#### Disabling Zoekt indexing

Zoekt indexing can be completely disabled. Pausing indexing is the preferred method to halt Zoekt indexing.

WARNING:
Indexed data will be stale after indexing is re-enabled. Reindexing from scratch may be necessary to ensure up to date search results.

* [`index_code_with_zoekt`](https://gitlab.com/gitlab-org/gitlab/blob/master/ee/config/feature_flags/development/index_code_with_zoekt.yml)

#### Shards management

At the moment, we have the `zoekt_shards` table for assigning shards. In order to move namespace from one shard to another, we need to reindex the data.

#### Limitations

1. Multiple shards and replication are not supported yet. You can follow the progress in <https://gitlab.com/groups/gitlab-org/-/epics/11382>.

## Architecture

### How Zoekt is used

In order to index repositories and provide search functionality we use 1 binary from the Zoekt repository and
1 binary from the gitlab-org repository:

* [`gitlab-zoekt-indexer`](https://gitlab.com/gitlab-org/gitlab-zoekt-indexer) is built using the
[`github.com/sourcegraph/zoekt`](https://github.com/sourcegraph/zoekt) and [`gitlab-org/gitaly`](https://gitlab.com/gitlab-org/gitaly/) libraries.
It is used to receive requests from GitLab and index provided repositories.
* [`zoekt-webserver`](https://github.com/sourcegraph/zoekt/tree/main/cmd/zoekt-webserver) is used to serve search requests. Needs to have access to index files produced by `gitlab-zoekt-indexer`.

### Zoekt API

#### Indexing

For `gitlab-zoekt-indexer` we use `/indexer/index` requests with repository URL and project ID:

```shell
curl -s -XPOST -d '{"CloneUrl":"https://gitlab.com/gitlab-org/gitlab.git","RepoId":278964, "FileSizeLimit": 2097152, "Timeout": "1h", "GitalyConnectionInfo": {"Address": "gitaly.address", "Storage": "default", "Path": "path/gitlab-org/gitlab.git"} }' -H 'Content-Type: application/json' https://zoekt-indexer.url/indexer/index
```

#### Delete

For `gitlab-zoekt-indexer` we use `/indexer/index/:repoId` requests with the project ID:

```shell
curl -s -XDELETE https://zoekt-indexer.url/indexer/index/278964
```

#### Searching

For `zoekt-webserver` we use the `/api/search` endpoint:

```shell
curl -s -XPOST -d '{"Q":"query","RepoIds":[278964],"Opts":{"TotalMaxMatchCount":20,"NumContextLines":1}}' 'https://zoekt-webserver.url/api/search'
```

### Indexer

#### Overview

Indexing happens in two scenarios:

* initial indexing - triggered by adding namespaces
* new events (e.g. git push) - webserver schedules sidekiq jobs that run indexers

#### Triggering indexing

Gitlab application will be scheduling sidekiq jobs. Once a namespace is enabled sidekiq jobs will be scheduled for it. You can always manually retrigger a project to be indexed from the Rails console with `Zoekt::IndexerWorker.perform_async(<project id>)`.

#### Sidekiq jobs

Examples of indexer jobs:

* `ee/app/workers/zoekt/indexer_worker.rb`

Logs available in centralised logging, see [Logging](../logging/README.md)

<!-- ## Performance -->

## Scalability

### How much Zoekt storage do we need

Zoekt index takes about 2.8 times of the source code in the indexed branch (excluding binary files). We also store bare repos as an intermediate step for generating the index files.
This is a significant storage overhead so we plan to optimize this in <https://gitlab.com/gitlab-org/gitlab/-/issues/384722>

<!-- ## Links to further Documentation -->
<!-- ## Availability -->

<!-- ## Durability -->

<!-- ## Security/Compliance -->

## Monitoring/Alerting

### Dashboards

There are a few dashboards to monitor Zoekt health:

* [Zoekt Health Dashboard](https://log.gprd.gitlab.net/app/r/s/jR5H5): Monitor search and indexing operations
* [Zoekt memory usage](https://thanos-query.ops.gitlab.net/graph?g0.expr=sum(process_resident_memory_bytes%7Benv%3D%22gprd%22,%20container%3D~%22zoekt.*%22%7D)%20by%20(container,%20pod)&g0.tab=0&g0.stacked=0&g0.range_input=2h&g0.max_source_resolution=0s&g0.deduplicate=1&g0.partial_response=0&g0.store_matches=%5B%5D&g0.step_input=60) : View memory utilization for Zoekt containers
* [Zoekt OOM errors](https://thanos.gitlab.net/graph?g0.expr=(sum%20by%20(container%2C%20pod%2C%20environment)%20(kube_pod_container_status_last_terminated_reason%7Benv%3D%22gprd%22%2C%20cluster%3D%22gprd-gitlab-gke%22%2C%20pod%3D~%22gitlab-gitlab-zoekt-%5B0-9%5D%2B%22%2C%20reason%3D%22OOMKilled%22%7D)%0A%20%20%20%20%20%20*%20on%20(container%2C%20pod%2C%20environment)%20group_left%0A%20%20%20%20%20%20sum%20by%20(container%2C%20pod%2C%20environment)%20(changes(kube_pod_container_status_restarts_total%7Benv%3D%22gprd%22%2C%20cluster%3D%22gprd-gitlab-gke%22%2C%20pod%3D~%22gitlab-gitlab-zoekt-%5B0-9%5D%2B%22%7D%5B1m%5D)%20%3E%200))%0A&g0.tab=0&g0.stacked=0&g0.range_input=12h&g0.max_source_resolution=0s&g0.deduplicate=1&g0.partial_response=0&g0.store_matches=%5B%5D): View any Out Of Memory exceptions for Zoekt containrs
* [Zoekt Info Dashboard](https://dashboards.gitlab.net/d/search-zoekt/search3a-zoekt-info)

### Kibana logs

GitLab application has a dedicated `zoekt.log` file for Zoekt-related log entries. This will be handled by the standard logging infrastructure. You may also find indexing related errors in `sidekiq.log` and search related errors in `production_json.log`.

As for `gitlab-zoekt-indexer` and `zoekt-webserver`, they write logs to stdout.
