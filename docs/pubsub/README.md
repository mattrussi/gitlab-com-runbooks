<!-- MARKER: do not edit this section directly. Edit services/service-catalog.yml then run scripts/generate-docs -->

**Table of Contents**

[[_TOC_]]

#  Pubsub Service
* [Service Overview](https://dashboards.gitlab.net/d/USVj3qHmk/logging)
* **Alerts**: https://alerts.gitlab.net/#/alerts?filter=%7Btype%3D%22pubsub%22%2C%20tier%3D%22inf%22%7D
* **Label**: gitlab-com/gl-infra/production~"Service:PubSub"

## Logging

* [stackdriver](https://console.cloud.google.com/logs)
* [multiple indexes in Kibana](https://log.gprd.gitlab.net/goto/2fc394521558a0bfed59f791295ffe51)

## Troubleshooting Pointers

* [Find a project from its hashed storage path](../gitaly/find-project-from-hashed-storage.md)
* [../kube/k8s-operations.md](../kube/k8s-operations.md)
* [../logging/logging_gcs_archive_bigquery.md](../logging/logging_gcs_archive_bigquery.md)
* [Diagnosis with Kibana](../onboarding/kibana-diagnosis.md)
* [../patroni/pg_collect_query_data.md](../patroni/pg_collect_query_data.md)
* [../patroni/postgresql-backups-wale-walg.md](../patroni/postgresql-backups-wale-walg.md)
* [Praefect error rate is too high](../praefect/praefect-error-rate.md)
* [PubSub Queuing Rate Increasing](pubsub-queing.md)
* [A survival guide for SREs to working with Redis at GitLab](../redis/redis-survival-guide-for-sres.md)
* [A survival guide for SREs to working with Sidekiq at GitLab](../sidekiq/sidekiq-survival-guide-for-sres.md)
* [Life of a Git Request](../tutorials/overview_life_of_a_git_request.md)
* [Camoproxy troubleshooting](../uncategorized/camoproxy.md)
<!-- END_MARKER -->


<!-- ## Summary -->

<!-- ## Architecture -->

<!-- ## Performance -->

<!-- ## Scalability -->

<!-- ## Availability -->

<!-- ## Durability -->

<!-- ## Security/Compliance -->

<!-- ## Monitoring/Alerting -->

<!-- ## Links to further Documentation -->
