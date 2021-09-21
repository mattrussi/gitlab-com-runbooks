## Deployment/Migration Failure Scenarios

[[_TOC_]]


This document lists and describes all the identified possible failure scenarios when [deploying and migrating to the new version of the container registry for GitLab.com](https://gitlab.com/groups/gitlab-org/-/epics/5523).

Please see the [architecture blueprint](https://docs.gitlab.com/ee/architecture/blueprints/container_registry_metadata_database/) and the [gradual migration plan](https://gitlab.com/gitlab-org/container-registry/-/issues/374) for additional context.

Failure scenarios are broken down by category (database, application, migration, etc.).

### Database

#### Primary Server Failure

##### Impact

- API unable to serve all `POST`/`PUT`/`PATCH`/`DELETE` requests ([4%](https://thanos.gitlab.net/new/graph?g0.expr=(sum(%0A%20%20%20%20rate(%0A%20%20%20%20%20%20registry_http_requests_total%7B%0A%20%20%20%20%20%20%20%20env%3D%22gprd%22%2C%0A%20%20%20%20%20%20%20%20code%3D~%22%5E2.*%22%2C%0A%20%20%20%20%20%20%20%20method%3D~%22put%7Cpatch%7Cpost%7Cdelete%22%0A%20%20%20%20%20%20%7D%5B7d%5D%0A%20%20%20%20)%0A)%0A%2F%20%0Asum(%0A%20%20%20%20rate(%0A%20%20%20%20%20%20registry_http_requests_total%7B%0A%20%20%20%20%20%20%20%20env%3D%22gprd%22%2C%0A%20%20%20%20%20%20%20%20code%3D~%22%5E2.*%22%0A%20%20%20%20%20%20%7D%5B7d%5D%0A%20%20%20%20)%0A))%20*%20100&g0.tab=1&g0.stacked=0&g0.range_input=1h&g0.max_source_resolution=0s&g0.deduplicate=1&g0.partial_response=0&g0.store_matches=%5B%5D&g1.expr=(sum(%0A%20%20%20%20rate(%0A%20%20%20%20%20%20registry_http_requests_total%7B%0A%20%20%20%20%20%20%20%20env%3D%22gprd%22%2C%0A%20%20%20%20%20%20%20%20code%3D~%22%5E2.*%22%2C%0A%20%20%20%20%20%20%20%20method%3D~%22get%7Chead%7Coptions%22%0A%20%20%20%20%20%20%7D%5B7d%5D%0A%20%20%20%20)%0A)%0A%2F%20%0Asum(%0A%20%20%20%20rate(%0A%20%20%20%20%20%20registry_http_requests_total%7B%0A%20%20%20%20%20%20%20%20env%3D%22gprd%22%2C%0A%20%20%20%20%20%20%20%20code%3D~%22%5E2.*%22%0A%20%20%20%20%20%20%7D%5B7d%5D%0A%20%20%20%20)%0A))%20*%20100&g1.tab=1&g1.stacked=0&g1.range_input=1h&g1.max_source_resolution=0s&g1.deduplicate=1&g1.partial_response=0&g1.store_matches=%5B%5D) of all traffic);
- API unable to serve all `GET`/`HEAD` requests ([96%](https://thanos.gitlab.net/new/graph?g0.expr=(sum(%0A%20%20%20%20rate(%0A%20%20%20%20%20%20registry_http_requests_total%7B%0A%20%20%20%20%20%20%20%20env%3D%22gprd%22%2C%0A%20%20%20%20%20%20%20%20code%3D~%22%5E2.*%22%2C%0A%20%20%20%20%20%20%20%20method%3D~%22put%7Cpatch%7Cpost%7Cdelete%22%0A%20%20%20%20%20%20%7D%5B7d%5D%0A%20%20%20%20)%0A)%0A%2F%20%0Asum(%0A%20%20%20%20rate(%0A%20%20%20%20%20%20registry_http_requests_total%7B%0A%20%20%20%20%20%20%20%20env%3D%22gprd%22%2C%0A%20%20%20%20%20%20%20%20code%3D~%22%5E2.*%22%0A%20%20%20%20%20%20%7D%5B7d%5D%0A%20%20%20%20)%0A))%20*%20100&g0.tab=1&g0.stacked=0&g0.range_input=1h&g0.max_source_resolution=0s&g0.deduplicate=1&g0.partial_response=0&g0.store_matches=%5B%5D&g1.expr=(sum(%0A%20%20%20%20rate(%0A%20%20%20%20%20%20registry_http_requests_total%7B%0A%20%20%20%20%20%20%20%20env%3D%22gprd%22%2C%0A%20%20%20%20%20%20%20%20code%3D~%22%5E2.*%22%2C%0A%20%20%20%20%20%20%20%20method%3D~%22get%7Chead%7Coptions%22%0A%20%20%20%20%20%20%7D%5B7d%5D%0A%20%20%20%20)%0A)%0A%2F%20%0Asum(%0A%20%20%20%20rate(%0A%20%20%20%20%20%20registry_http_requests_total%7B%0A%20%20%20%20%20%20%20%20env%3D%22gprd%22%2C%0A%20%20%20%20%20%20%20%20code%3D~%22%5E2.*%22%0A%20%20%20%20%20%20%7D%5B7d%5D%0A%20%20%20%20)%0A))%20*%20100&g1.tab=1&g1.stacked=0&g1.range_input=1h&g1.max_source_resolution=0s&g1.deduplicate=1&g1.partial_response=0&g1.store_matches=%5B%5D) of all traffic). This will change once we deliver *active* database load-balancing (routing reads to a secondary server);
- GC unable to process tasks.

**Note:** During [Phase 1](https://gitlab.com/gitlab-org/container-registry/-/issues/374#phase-1-the-metadata-db-serves-new-repositories), only requests that target *new* repositories can be affected.

##### Expected app behavior on failure

- API and GC handle refused or timed out database connections gracefully;
- Connections are retried once (at the database driver level). In case of failure, connections are discarded and requests halted with a `503 Service Unavailable` response;
- A new request leads to a new connection attempt.

##### Observability

- Errors show up in Sentry and logs;
- Grafana dashboards reflect the impact scale.

##### Recovery definition

Primary server is back online. Either the same instance or a promoted replica.

##### Expected app behavior on recovery

API and GC resume operations normally, without external intervention.

##### Mitigation

Re-establish normal operation of database cluster/network.

##### Possible corrective actions

- Database cluster deployment adjustments;
- Escalation to development in case of odd use pattern.

#### Single Secondary Server Failure

NA. Needs to be revisited once we deliver active database load-balancing.

#### Secondary Servers Failure

NA. Needs to be revisited once we deliver active database load-balancing.

#### Connection Pool Saturation

##### Impact

- API unable to serve requests;
- GC unable to process tasks.

##### Expected app behavior on failure

- API and/or GC fail to pull a connection from a pool at any given time;
- API requests will timeout with a `500 Internal Server Error` response.

##### Observability

- Errors show up in Sentry and logs;
- Grafana dashboards reflect the magnitude of the impact on the API and pool saturation metrics.

##### Recovery definition

Connection pool is no longer saturated.

##### Expected app behavior on recovery

API and GC resume operations normally. External intervention may be required.

##### Mitigation

Increase connection pool limits on application/PGBouncer if it is due to a legitimate traffic increase.

##### Possible corrective actions

- Adjust connection pool limits on application/PGBouncer.
- Try to optimize slow queries.
- Switch to a faster DB machine type.

#### Excessive Latency

##### Impact

- Drop on API request and GC run rates;
- A portion of API requests and GC runs may timeout.

##### Expected app behavior on failure

API requests and GC runs may timeout with a `500 Internal Server Error` response.

##### Observability

- Errors show up in Sentry and logs;
- Grafana dashboards reflect the impact scale.

##### Recovery definition

Latency is back to normal levels.

##### Expected app behavior on recovery

API and GC resume operations normally, without external intervention.

##### Mitigation

Re-establish normal operation of database cluster/network.

##### Possible corrective actions

Escalation to development in case of odd use pattern.

#### Failed Schema Migration

This applies to both invalid migrations (should be impossible, as we test them before releasing, unless another actor has changed something on the database schema) and timeouts.

##### Impact

- Failed migration job (Charts) that preceeds the application upgrade;

- Blocked deployment due to the above.

##### Expected app behavior on failure

Normal behaviour. Each migration is performed within a transaction and automatically rolled back in case of error. Due to the blocked deployment, the application version won't be updated and therefore there is no impact on user-facing behaviour.

##### Observability

The registry CLI will output the corresponding error. For example:

```shell
ERRO[0000] Exec                                          args="[]" database=registry err="ERROR: column \"stop_level_namespace_id\" does not exist (SQLSTATE 42703)" pid=77733 sql="CREATE INDEX IF NOT EXISTS index_repositories_on_top_level_namespace_id_and_parent_id ON repositories USING btree (stop_level_namespace_id, parent_id)"
failed to run database migrations: ERROR: column "stop_level_namespace_id" does not exist (SQLSTATE 42703) handling 20210503145616_create_repositories_table⏎  
```

##### Recovery definition

Retrying the corresponding migration suceeds.

##### Expected app behavior on recovery

NA

##### Mitigation

If due to an invalid migration, this needs to be fixed by development before retrying. If due to a timeout, we must determine why it's taking too long to complete and if there are any ongoing conflicting queries.

##### Possible corrective actions

### Online Garbage Collection

#### Fatal Error During Run

##### Impact

- Task fails to be processed;
- GC queues size may increase if it's not a transient error.

##### Expected app behavior on failure

- GC attempts to postpone review of the task to a future date. If failed, original review date remains unchanged, but this has little to no impact (ideally we should postpone the next review in case of error);
- The GC workers should backoff exponentially for every failed run, up to the maximum configured duration (24h by default).

##### Observability

- Errors show up in Sentry and logs;
- Grafana dashboards reflect the magnitude of the impact on the [Garbage Collection Detail](https://dashboards.gitlab.net/d/registry-gc/registry-garbage-collection-detail?orgId=1) dashboard.

##### Recovery definition

Normal operation re-established. Root cause mitigated.

##### Expected bpp behavior on recovery

GC workers resume normal operation. The next run will happen automatically after the last exponential backoff.

##### Mitigation

NA

##### Possible corrective actions

Escalation to development in case of  error unrelated with database/storage connection failures.

#### False Positive

##### Impact

A manifest or blob was garbage collected when it should not.

##### Expected app behavior on failure

Download requests for the corresponding image will fail with a `404 Not Found`.

##### Observability

It is not possible for us to identify this among all other `404 Not Found` responses, which happen quite frequently. Only end users are able to detect this problem, if it ever occurs. For example, they may have sucessfully pushed an image and then tried to pull it the day after but without success.

##### Recovery definition

The deleted image is available once again.

##### Expected app behavior on recovery

Download requests for the corresponding image will succeed.

##### Mitigation

If possible, the easiest mitigation is to rebuild the image from the *client side*. This can be for example, retrying the CI job that was responsible for building the image in the first place.

Alternatively, on the *server side*, once we know the corresponding repository and tag, we can look at the online GC logs to identify when the corresponding image manifest and/or layers where deleted and the reason why.

If proven to be a false positive, online GC should be disabled until further analysis. This can be done by setting [`gc.disabled`](https://gitlab.com/gitlab-org/container-registry/-/blob/e58e8c2f66c246fbdae7ace849238b08e7bfbb25/docs/configuration.md#gc) to `true` in the registry config. After that, we can attempt to recover the deleted manifest or blob.

**TODO:** Detail server side recovery mechanism. This probably deserves a separate section/doc. The raw idea would be: 1. Identify manifest and/or blob digests; 2. Restore blobs on the storage bucket (GCS deleted objects are retained for 30 days); 3. Restore database metadata from filesystem, which will be available as long as write mirroring is enabled (this metadata is not garbage collected).

##### Possible corrective actions

Identify and fix bug on the online GC review process.

#### False Negative

##### Impact

A manifest or blob that should have been garbage collected was not.

##### Expected app behavior on failure

Download requests for the corresponding image will succeed.

##### Observability

It is not possible for us to identify this. Only end users are able to detect this problem, if it ever occurs. For example, they may have deleted all tags for an image but the underlying manifest and layers remain available.

##### Recovery definition

The manifest or blobs are garbage collected and no longer acessible.

##### Expected app behavior on recovery

Download requests for the corresponding image will fail with `404 Not Found`.

##### Mitigation

This is considered low in criticality and priority. It should be escalated to the development team for analysis.

Once we know the corresponding repository and manifest or blobs, we can look at the online GC logs to identify that the corresponding artifacts where already reviewed and the result was "not dangling". We should then look at the database to indentify any remaining references for the manifest (tags or other manifests) or blob (manifest).

If proven to be a false negative, the bug on the online GC review process should be fixed and the corresponding manifest or blobs re-scheduled for review.

**TODO:** Detail manual reschedule mechanism. This is likely an insert on the DB review queue tables.

##### Possible corrective actions

Identify and fix bug on the online GC review process.

### Migration of New Repositories

#### Old Repository Handled by New Code Path

##### Impact

An old repository was handled by the new code path.

##### Expected app behavior on failure

If no writes to the new path were made, read requests made against this repository will fail with `404 Not Found`.

Write requests should succeed, writing data to the new code path.

For subsequent read requests, data written to the new path will be visible to the UI and available to pull. While the old data will not appear in the UI and will not be available to pull, failing with `404 Not Found`.

##### Observability

The logs in Kibana will always include `serving request in migration mode` for once for each request made in migration mode. This log entry will contain the path that the repository followed, but its presence is not a signal or alert for this scenario in particular. 

End users will observe this issue as older tags not suddenly and consistently not appearing in the UI and older images suddenly and consistently failing to pull. While newer tags and images consistently remain visible in the UI and pullable.

##### Recovery definition

Requests are once again routed to the old code path.

##### Expected app behavior on recovery

If no writes to the new path were made, read requests made against this repository will succeed again.

Write requests should succeed, writing data to the old code path.

If data were written to the new code path, those images would no longer be visible in the UI or pullible.

##### Mitigation

If possible, newer images that were pushed during this scenario should be rebuilt from the client side.

On the server side, we should remove this repository and all of its images _from the database_. This will ensure a clean environment for when this repository is migrated.

##### Possible corrective actions

This scenario represents a relatively serious situation, as serving repositories via the old code path is the default scenario during migration.

If this issue is a bug, it would need to be identified and patched by the registry development team.

If there is an intermittent GCS issue, it's possible that an existing path would return `404 Not Found`, rather than a more appropriate error. This would cause a single repository old, but otherwise eligible, repository to flip over to the new side and flip back to the old side again, likely without our direct intervention, or possibly knowledge.

#### Eligible New Repository Handled by Old Code Path

##### Impact

A new repository was handled by the old code path.

##### Expected app behavior on failure

If no writes to the old path were made, read requests made against this repository will fail with `404 Not Found`.

Write requests should succeed, writing data to the old code path.

For subsequent read requests, data written to the old path will be visible to the UI and available to pull. While the data on the new path will not appear in the UI and will not be available to pull, failing with `404 Not Found`.

##### Observability

The logs in Kibana will always include `serving request in migration mode` for once for each request made in migration mode. This log entry will contain the path that the repository followed, but its presence is not a signal or alert for this scenario in particular. 

End users will observe this issue as older tags not suddenly and consistently not appearing in the UI and older images suddenly and consistently failing to pull. While newer tags and images consistently remain visible in the UI and pullable.

##### Recovery definition

Requests are once again routed to the new code path.

##### Expected app behavior on recovery

If no writes to the old path were made, read requests made against this repository will succeed again.

Write requests should succeed, writing data to the new code path.

If data were written to the old code path, those images would no longer be visible in the UI or pullible.

##### Mitigation

On the server side during [Phase 2](https://gitlab.com/gitlab-org/container-registry/-/issues/374#phase-2-migrate-existing-repositories), the data on the old prefix on the GCS bucket will not cause future requests to be routed to the old code path, so we are not required to remove it.

If possible, newer images that were pushed during this scenario should be rebuilt from the client side.

##### Possible corrective actions

For [Phase 1](https://gitlab.com/gitlab-org/container-registry/-/issues/374#phase-1-the-metadata-db-serves-new-repositories), it's possible that the `container_registry_migration_phase1_deny` feature flag was set for a repository what was previously eligible. This feature flag would need to be removed, and we **must** remove this repository and all of its images _from the old prefix on the GCS bucket_ — otherwise eligible repositories that are present on the old prefix, will always be served by the old code path during Phase 1.

For [Phase 2](https://gitlab.com/gitlab-org/container-registry/-/issues/374#phase-2-migrate-existing-repositories), this likely indicates a bug in the container registry. Either in the logic to identify a new repository, or in the routing logic. This issue would need to investigated and fixed by the registry development team.

#### Non-Eligible New Repository Handled by New Code Path

##### Impact

An ineligible new repository was handled by the new code path.

##### Expected app behavior on failure

Read requests will initially fail before writes are made, but they should do so in the same way as with any non-existing repository.

Write requests should succeed, writing data to the new code path.

For subsequent read requests, data written to the new path will be visible to the UI and available to pull.

##### Observability

The logs in Kibana will always include `serving request in migration mode` for once for each request made in migration mode. This log entry will contain the path that the repository followed, but its presence is not a signal or alert for this scenario in particular.

End users _will not_ observe this issue as this will only happen with new repositories and ll the data written to the repository will be on the new side, so there will be no data consistency issues for the duration of this incident.

##### Recovery definition

This repository begins to be served by the old code path.

##### Expected app behavior on recovery

Write requests should succeed, writing data to the old code path.

This incident cannot occur in a meaningful way without data written to the new code path, those images would no longer be visible in the UI or pullible.

##### Mitigation

On the server side during [Phase 1](https://gitlab.com/gitlab-org/container-registry/-/issues/374#phase-1-the-metadata-db-serves-new-repositories), data written to the database prefix on the GCS bucket **will not** cause future requests to be routed to the new code path, so we are not required to remove it to immediately resolve the issue. However, the data on the database and metadata on the new storage prefix should be removed afterward, as data on the database during [Phase 2](https://gitlab.com/gitlab-org/container-registry/-/issues/374#phase-2-migrate-existing-repositories) will cause future requests to be routed to the new code path.

On the server side during Phase 2, data written to the database prefix on the GCS bucket **will** cause future requests to be routed to the new code path, so we must remove it to immediately resolve the issue. Metadata on the new storage prefix should be removed afterward, but this is not required to immediate resolve the issue.

If possible, images that were pushed during this scenario should be rebuilt from the client side.

##### Possible corrective actions

The most likely scenario for a single repository experiencing this issue that a `container_registry_migration_phase1_deny` feature flag is not being detected or honored by the registry auth service, so that the auth service is not populating the `migration.eligible` header appropriately.

This issue would need to investigated and fixed by the registry development team.

### < Category >

#### < Failure >

##### Impact

##### Expected app behavior on failure

##### Observability

##### Recovery definition

##### Expected bpp behavior on recovery

##### Mitigation

##### Possible corrective actions
