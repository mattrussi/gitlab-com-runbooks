# Thanos Query and Stores

When you do a query on [Thanos](https://thanos.gitlab.net), the query is fanned out across different stores to search metrics.
Thanos announces the labelsets for each store which you can see on the [Status>Targets page](https://thanos.gitlab.net/targets).
This way the querier can know where to fan out queries and skip other stores.

In some rare cases, you may see an error like "No StoreAPIs matched for this query".  In one [incident](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/8567#note_1319938832), this was due to a combination of errors.  First, `Use Partial Repsonse` was not checked so that means all stores must be successfully queried to get a full response.  Second, one store acceesed via Thanos recieve had a bug and was not advertising its labelsets.  Restarting the pod helped bring things back to normal - labelsets were advertised and the queries could be managed properly.
