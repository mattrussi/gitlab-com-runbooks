<!-- MARKER: do not edit this section directly. Edit services/service-catalog.yml then run scripts/generate-docs -->

**Table of Contents**

[[_TOC_]]

# External-dns Service

* [Service Overview](https://dashboards.gitlab.net/d/external-dns-main/external-dns-overview)
* **Alerts**: <https://alerts.gitlab.net/#/alerts?filter=%7Btype%3D%22external-dns%22%2C%20tier%3D%22sv%22%7D>
* **Label**: gitlab-com/gl-infra/production~"Service:ExternalDNS"

## Logging

* [Stackdriver logs](https://cloudlogging.app.goo.gl/UY7qbsc5KoZZALtT7)

<!-- END_MARKER -->

## Operations

ExternalDNS allows us to generate DNS records for k8s resources, simplifying
references to them across our infrastructure

### Infrastructure

ExternalDNS is deployed as a k8s workload [configured in the gitlab-helmfiles repo](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-helmfiles/-/tree/master/releases/external-dns).
At the configured interval, it queries the Kubernetes API to retrieve
resources with the relevant annotations and creates or updates DNS records for them.
[A Terraform module](https://ops.gitlab.net/gitlab-com/gl-infra/config-mgmt/-/tree/master/modules/gke-external-dns)
configures the GCP DNS zone and a service account with access to it.

### Configuration

To instruct ExternalDNS to maintain a DNS record for a given k8s resource, annotate it with the key `external-dns.alpha.kubernetes.io/hostname`; the value is the address you want to associate with that
resource. To avoid the risk of stale records (given propagation delay), stable IPs should be used. In GKE we can accomplish this by using `Services` of type `LoadBalancer`, and adding the ExternalDNS
annotation to that resource.

See <https://github.com/kubernetes-sigs/external-dns/> for more details

<!-- ## Summary -->

<!-- ## Architecture -->

<!-- ## Performance -->

<!-- ## Scalability -->

<!-- ## Availability -->

<!-- ## Durability -->

<!-- ## Security/Compliance -->

<!-- ## Monitoring/Alerting -->

<!-- ## Links to further Documentation -->
