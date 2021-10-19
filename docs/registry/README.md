<!-- MARKER: do not edit this section directly. Edit services/service-catalog.yml then run scripts/generate-docs -->

**Table of Contents**

[[_TOC_]]

#  Registry Service
* [Service Overview](https://dashboards.gitlab.net/d/registry-main/registry-overview)
* **Alerts**: https://alerts.gitlab.net/#/alerts?filter=%7Btype%3D%22registry%22%2C%20tier%3D%22sv%22%7D
* **Label**: gitlab-com/gl-infra/production~"Service:Registry"

## Logging

* [Registry](https://log.gprd.gitlab.net/goto/9ec8a738ca23a17a9d7b61b4c3a9c96e)
* [haproxy](https://console.cloud.google.com/logs/viewer?project=gitlab-production&interval=PT1H&resource=gce_instance&customFacets=labels.%22compute.googleapis.com%2Fresource_name%22&advancedFilter=labels.tag%3D%22haproxy%22%0Alabels.%22compute.googleapis.com%2Fresource_name%22%3A%22fe-registry-%22)
* [Kubernetes](https://log.gprd.gitlab.net/goto/d614a5576099ff797be559c89fe88baa)

## Troubleshooting Pointers

* [../cloudflare/managing-traffic.md](../cloudflare/managing-traffic.md)
* [../consul/interaction.md](../consul/interaction.md)
* [../frontend/ban-netblocks-on-haproxy.md](../frontend/ban-netblocks-on-haproxy.md)
* [../frontend/haproxy.md](../frontend/haproxy.md)
* [../kube/k8s-operations.md](../kube/k8s-operations.md)
* [../kube/kubernetes.md](../kube/kubernetes.md)
* [../onboarding/gitlab.com_on_k8s.md](../onboarding/gitlab.com_on_k8s.md)
* [../onboarding/kibana-diagnosis.md](../onboarding/kibana-diagnosis.md)
* [app-db-conn-pool-saturation.md](app-db-conn-pool-saturation.md)
* [gitlab-registry.md](gitlab-registry.md)
* [migration-failure-scenarios.md](migration-failure-scenarios.md)
* [online-gc-high-overdue-tasks.md](online-gc-high-overdue-tasks.md)
* [../uncategorized/delete-projects-manually.md](../uncategorized/delete-projects-manually.md)
* [../uncategorized/tweeting-guidelines.md](../uncategorized/tweeting-guidelines.md)
* [../vault/vault.md](../vault/vault.md)
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
