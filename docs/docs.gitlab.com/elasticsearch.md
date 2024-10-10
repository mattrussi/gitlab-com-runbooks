# Elasticsearch for docs.gitlab.com

The Technical Writing team implemented Elasticsearch for the Docs website
in Q3 of 2024.

## Infrastructure

The Elastic deployment for GitLab Docs is managed in the same Elastic Cloud
organization as the Elastic deployments for GitLab.com.

See [Elastic Cloud](../elastic/elastic-cloud.md) for access information.

- [`gitlab-docs-website` Elastic admin](https://gitlab-docs-website.kb.us-central1.gcp.cloud.es.io:9243/app/home#/)
- [Deployment health](https://cloud.elastic.co/deployments/6812a4f2d673478cabffaf43ffbaab56/health)
- [Logs and metrics](https://cloud.elastic.co/deployments/6812a4f2d673478cabffaf43ffbaab56/logs-metrics)
- [GitLab Docs search indices](https://gitlab-docs-website.kb.us-central1.gcp.cloud.es.io:9243/app/enterprise_search/content/search_indices)

The current production index is `search-gitlab-docs-nanoc`. It is populated via Elastic's
web crawler, which runs every four hours.

## API keys

Because the Docs website connects to Elastic from frontend code,
the API key is a public key, with special configuration to make
sure it only has read-only access.

The key is loaded from the `ELASTIC_KEY` CI variable.

See [this page](https://gitlab.com/gitlab-org/gitlab-docs/-/blob/main/doc/search.md?ref_type=heads) for directions for rotating the key.
