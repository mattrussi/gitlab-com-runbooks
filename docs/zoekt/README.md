<!-- MARKER: do not edit this section directly. Edit services/service-catalog.yml then run scripts/generate-docs -->

**Table of Contents**

[[_TOC_]]

# Zoekt Service

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

#### Enabling/Disabling Zoekt integration

You can prevent Gitlab from using Zoekt integration for searching, but leave the integration itself enabled. An example of when this is useful is during an incident where users are experiencing slow searches or Zoekt is unresponsive.

Currently we use 2 feature flags for Zoekt:

* [`index_code_with_zoekt`](https://gitlab.com/gitlab-org/gitlab/blob/master/ee/config/feature_flags/development/index_code_with_zoekt.yml)
* [`search_code_with_zoekt`](https://gitlab.com/gitlab-org/gitlab/blob/master/ee/config/feature_flags/development/search_code_with_zoekt.yml)

For indexing and searching respectively. These feature flags can be triggered independently.

#### Shards management

At the moment, we have the `zoekt_shards` table for assigning shards. In order to move namespace from one shard to another, we need to reindex the data.

#### Limitations

1. We can't delete data from the index, you can follow the progress in <https://gitlab.com/gitlab-org/gitlab/-/issues/389760>
1. Project deletions and transfers are not implemented. You can follow the progress in <https://gitlab.com/gitlab-org/gitlab/-/issues/389760> and <https://gitlab.com/gitlab-org/gitlab/-/issues/389761> respectively.

## Architecture

### How Zoekt is used

In order to index repositories and provide search functionality we use 2 binaries from the Zoekt repository:

* [`zoekt-dynamic-indexserver`](https://github.com/sourcegraph/zoekt/tree/main/cmd/zoekt-dynamic-indexserver) is
used to receive requests from GitLab and index provided repositories.
* [`zoekt-webserver`](https://github.com/sourcegraph/zoekt/tree/main/cmd/zoekt-webserver) is used to serve search requests. Needs to have access to index files produced by `zoekt-dynamic-indexserver`.

`zoekt-dynamic-indexserver` also shells out [`zoekt-git-clone`](https://github.com/sourcegraph/zoekt/tree/main/cmd/zoekt-git-clone) and [`zoekt-git-index`](https://github.com/sourcegraph/zoekt/tree/main/cmd/zoekt-git-index),
which means that these binaries should also be present in the path. In turn `zoekt-git-clone` is shelling out to `git` so this must also be in the path.

### Zoekt API

#### Indexing

For `zoekt-dynamic-indexserver` we use `/index` requests with repository URL and project ID:

```shell
curl -s -XPOST -d '{"CloneUrl":"https://gitlab.com/gitlab-org/gitlab.git","RepoId":278964}' -H 'Content-Type: application/json' https://zoekt-indexer.url/index
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

GitLab application has a dedicated `zoekt.log` file for Zoekt-related log entries. This will be handled by the standard logging infrastructure. You may also find indexing related errors in `sidekiq.log` and search related errors in `production_json.log`.

As for `zoekt-dynamic-indexserver` and `zoekt-webserver`, they write logs to stdout.
