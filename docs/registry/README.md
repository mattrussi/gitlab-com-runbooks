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

* [Cloudflare: Managing Traffic](../cloudflare/managing-traffic.md)
* [Interacting with Consul](../consul/interaction.md)
* [Blocking individual IPs and Net Blocks on HA Proxy](../frontend/ban-netblocks-on-haproxy.md)
* [HAProxy management at GitLab](../frontend/haproxy.md)
* [../kube/k8s-operations.md](../kube/k8s-operations.md)
* [Kubernetes](../kube/kubernetes.md)
* [Gitlab.com on Kubernetes](../onboarding/gitlab.com_on_k8s.md)
* [Diagnosis with Kibana](../onboarding/kibana-diagnosis.md)
* [Database Connection Pool Saturation](app-db-conn-pool-saturation.md)
* [Container Registry CDN](cdn.md)
* [gitlab-registry.md](gitlab-registry.md)
* [migration-failure-scenarios.md](migration-failure-scenarios.md)
* [High Number of Overdue Online GC Tasks](online-gc-high-overdue-tasks.md)
* [Deleting a project manually](../uncategorized/delete-projects-manually.md)
* [An impatient SRE's guide to deleting alerts](../uncategorized/deleting-alerts.md)
* [Tweeting Guidelines](../uncategorized/tweeting-guidelines.md)
* [Gitlab Vault](../vault/vault.md)
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
