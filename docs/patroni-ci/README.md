<!-- MARKER: do not edit this section directly. Edit services/service-catalog.yml then run scripts/generate-docs -->

**Table of Contents**

[[_TOC_]]

# Patroni-ci Service

* [Service Overview](https://dashboards.gitlab.net/d/patroni-ci-main/patroni-ci-overview)
* **Alerts**: <https://alerts.gitlab.net/#/alerts?filter=%7Btype%3D%22patroni-ci%22%2C%20tier%3D%22db%22%7D>
* **Label**: gitlab-com/gl-infra/production~"Service:Postgres"

## Logging

* [Postgres](https://log.gprd.gitlab.net/goto/d0f8993486c9007a69d85e3a08f1ea7c)
* [system](https://log.gprd.gitlab.net/goto/3669d551a595a3a5cf1e9318b74e6c22)

## Troubleshooting Pointers

* [Steps to Recreate/Rebuild the CI CLuster using a Snapshot from the Master cluster (instead of pg_basebackup)](rebuild_ci_cluster_from_prod.md)
* [Recovering from CI Patroni cluster lagging too much or becoming completely broken](recovering_patroni_ci_intense_lagging_or_replication_stopped.md)
* [OS Upgrade Reference Architecture](../patroni/os_upgrade_reference_architecture.md)
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
