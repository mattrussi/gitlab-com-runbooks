<!-- MARKER: do not edit this section directly. Edit services/service-catalog.yml then run scripts/generate-docs -->

**Table of Contents**

[[_TOC_]]

# CI Postgres (Patroni) Service

* [Service Overview](https://dashboards.gitlab.net/d/patroni-ci-main/patroni-ci-overview)
* **Alerts**: <https://alerts.gitlab.net/#/alerts?filter=%7Btype%3D%22patroni-ci%22%2C%20tier%3D%22db%22%7D>
* **Label**: gitlab-com/gl-infra/production~"Service::PatroniCI"

## Logging

* [Postgres](https://log.gprd.gitlab.net/goto/d0f8993486c9007a69d85e3a08f1ea7c)
* [system](https://log.gprd.gitlab.net/goto/3669d551a595a3a5cf1e9318b74e6c22)

## Troubleshooting Pointers

* [../ci-runners/service-ci-runners.md](../ci-runners/service-ci-runners.md)
* [Recovering from CI Patroni cluster lagging too much or becoming completely broken](recovering_patroni_ci_intense_lagging_or_replication_stopped.md)
* [Steps to create (or recreate) a Standby CLuster using a Snapshot from a Production cluster as Master cluster (instead of pg_basebackup)](../patroni/build_cluster_from_snapshot.md)
* [OS Upgrade Reference Architecture](../patroni/os_upgrade_reference_architecture.md)
* [Handling Unhealthy Patroni Replica](../patroni/unhealthy_patroni_node_handling.md)
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
