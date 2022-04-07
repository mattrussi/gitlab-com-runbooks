# Container Registry Migration Phase 2

## Summary

This runbook contains operational details about Phase 2 of the [GitLab.com Container Registry migration](https://gitlab.com/groups/gitlab-org/-/epics/5523). This migration is split into two phases:

- **Phase 1**: Route newly created container repositories to the new platform (complete).
- **Phase 2**: Import existing container repositories to the new platform.

Phase 2 is driven by Rails using background workers, which invoke new endpoints on the Container Registry API to initiate/poll/cancel the migration of existing repositories from the old platform to the new one.

The migration of a given container repository is split into two passes:

- **Pre-import**: On the first pass, the registry will scan the repository data on the GCS bucket and register all tagged (and only the tagged) manifests and their referenced layers in the metadata DB, but not the tags. It will also copy (not move) these layer blobs from their current location in the GCS bucket to a new location under the `gitlab/` root prefix (where all the blobs registered in the metadata DB live);

- **Final import**: On the second pass, the registry will scan the repository again and import any manifests and layers that might have been added since the pre-import, but it will also register the actual tags. A read-only period is enforced during this pass, preventing writes against the repository.

It is Rails' responsibility to trigger each of these phases in this specific order. This is done by background workers (Sidekiq), which invoke new endpoints on the Container Registry API. Internally, the registry spawns a goroutine to process each (pre)import and notifies Rails about its completion asynchronously, using a dedicated API endpoint.

Please see the [corresponding section](https://gitlab.com/gitlab-org/container-registry/-/issues/374#phase-2-migrate-existing-repositories) of the migration plan.

## Relevant Documentation

- [Migration plan](https://gitlab.com/gitlab-org/container-registry/-/issues/374): Explains all the project phases in detail.
- [Migration API spec](https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs-gitlab/api.md#import-repository): The specification for the new endpoints on the registry API which are consumed exclusively by Rails.
- [Rails spec](https://gitlab.com/groups/gitlab-org/-/epics/7316#note_897867569): The implementation details of the logic that allows driving the migration from Rails.
- [Readiness review](https://gitlab.com/gitlab-com/gl-infra/readiness/-/blob/master/container-registry-migration-phase2/index.md): Production readiness review for Phase 2.

## Technical Details

### Background Workers

See `Workers` section in the [Rails spec](https://gitlab.com/groups/gitlab-org/-/epics/7316#note_897867569) for a list and description of each involved background worker.

### Application Settings

#### Rails

See `Application settings` section in the [Rails spec](https://gitlab.com/groups/gitlab-org/-/epics/7316#note_897867569).

#### Registry

See the [registry documentation](https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/configuration.md#migration).

### Feature Flags

Because the migration is driven by Rails, we can rely on a set of feature flags to control the migration. See `Feature flags` section in the [Rails spec](https://gitlab.com/groups/gitlab-org/-/epics/7316#note_897867569).

The most important one is `container_registry_migration_phase2_enabled`, which is the global switch. This can be turned off if suspecting issues related to the migration.

All feature flags are tracked in a single [https://gitlab.com/gitlab-org/gitlab/-/issues/350543](rollout issue).

## Observability

### Metrics

Below is a list of Grafana dashboards and the most relevant metrics within:

- [registry: Migration Detail](https://dashboards.gitlab.net/d/registry-migration/registry-migration-detail):
  - Count of top-level namespaces and repositories registered on the metadata DB;
  - Traffic share for the new code path;
  - RPS, latency, and error rate of import API requests;
  - Rate, latency, and number of inflight imports (broken down by import type);
  - Rate and latency of failed imports (broken down by import type);
  - Worker saturation per instance;
  - Row count metrics for the number and status of container repositories.

- [registry: Storage Detail](https://dashboards.gitlab.net/d/registry-storage/registry-storage-detail):
  - Rate of `429 Too Many Requests` responses from GCS. Used to monitor possible rate limits imposed by Google;

- [registry: Database Detail](https://dashboards.gitlab.net/d/registry-database/registry-database-detail):
   - RPS, latency and error rate for queries (each identified by a unique name);
   - Overall, table bloat and index bloat size;
   - Application-side connection pool metrics. 

### Logs

#### Registry

 Use [this view](https://log.gprd.gitlab.net/goto/76ae0c00-b666-11ec-b73f-692cc1ae8214) to monitor ongoing (pre)imports:

![phase2-registry-log-overview.png](./images/phase2-registry-log-overview.png)

You can tell whether a request initiated a pre or a final import by looking at the `?import_type` query parameter.

To delve into the detailed logs of a specific (pre)import, just filter by the corresponding `json.correlation_id` and disable the `json.uri` filter:

![phase2-registry-log-detail.png](./images/phase2-registry-log-detail.png)

#### Rails

Use [this view](https://log.gprd.gitlab.net/goto/224257f0-b668-11ec-afaf-2bca15dfbf33) to monitor the Rails workers:

![phase2-rails-log-workers-overview.png](./images/phase2-rails-log-workers-overview.png)

## Troubleshooting

### Rails Console Tips

- Identify the following repository on the queue to be migrated:

  ```rb
  ContainerRepository.ready_for_import.take
  ```

- Identify the next aborted repository import on the queue to be retried (takes precedence over the above):

  ```rb
  ContainerRepository.with_migration_state('import_aborted').take
  ```

- Identify migration status of a given repository:
  
  ```rb
  repo = ContainerRepository.find_by_path(ContainerRegistry::Path.new('path/to/repo'))
  repo.migration_state
  ```

  Refer to the `State machine` section in the [Rails spec](https://gitlab.com/groups/gitlab-org/-/epics/7316#note_897867569) for more details about each state.


### Registry Database Tips

- Find a specific repository by path, including its migration status:

  ```sql
  select * from repositories where path = 'path/to/repo';

### Potentially Stalled Imports

As explained in the [Summary](#summary), a repository will remain in read-only mode for as long as its migration status is `importing` on the Rails side (which will refuse to serve JWT tokens with write permissions for that repository) and/or `import_in_progress` on the registry side (which will refuse serving write requests for that repository to account for previously emitted but not yet expired JWT tokens with write permissions).

As explained in the [Rails spec](https://gitlab.com/groups/gitlab-org/-/epics/7316#note_897867569), we have automated mechanisms to ensure that repositories do not remain in this state for longer than expected. However, if something goes wrong, a repository migration will be considered stalled.

This can happen in the following scenarios:

- An unexpected issue on the Rails side end up leading to marking the repository as "importing" when it is not (or no longer);
- The registry failed to record in its database that the import was completed (either with success or error);
- The registry was not able to deliver the async notification to Rails, and Rails also failed to poll for the update due to an expected issue.

We have [metrics](https://dashboards.gitlab.net/d/registry-migration/registry-migration-detail?orgId=1&viewPanel=136) and [alerts](https://gitlab.com/gitlab-com/runbooks/-/tree/master/rules/container-registry-migration-phase2.yml) in place to detect potentially stalled imports and will be monitoring these closely during the migration.

If, for some reason, a problem around this is detected, please disable the global feature flag (`container_registry_migration_phase2_enabled`) to avoid further occurrences and report the situation to the development team (Package) ASAP. They are responsible for validating the root cause and determining the best action to take if a problem is confirmed. That said, if needed, we can resort to the Rails console to force cancel an ongoing import (stalled or not) across Rails and registry, ensuring that the repository is unlocked on both sides:

```rb
repo = ContainerRepository.find_by_path(ContainerRegistry::Path.new('path/to/repo'))
repo.cancel_migration(force: true)
```

Rails will no longer refuse to serve JWT tokens for the corresponding repository as soon as this is done. On the registry side, any inbound requests will be served through the old code path (not using the metadata database but rather the data in the old bucket partition). This gives us time to investigate the problem, fix it, and later retry the migration.
