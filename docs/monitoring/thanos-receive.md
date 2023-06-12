# Thanos Receive

Docs: <https://thanos.io/tip/components/receive.md/>

Thanos Receive implements a remote write endpoint for Prometheus.  We are using it to more easily ingest metrics from various projects.

The receivers[run in ops](https://gitlab.com/gitlab-com/gl-infra/readiness/-/blob/master/thanos/overview.md) and are deployed by
[k8s-workdloads helm charts](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-helmfiles/-/tree/master/releases/thanos/receivers).

## Receive Components

There are 4 components that make up the receiver.

#### Nginx

Nginx is currently used for autthentication and tenant head injection.
When a request is sent to the remote-write endpoint, nginx first authenticates the credentials using htpasswd/basicAuth, and then maps the `THANOS_TENANT` header to the username.

#### Receive Distributor (Router)

The distributor (AKA router) is responsible for routing requests to downstream receivers.
It leverages a hashring config file `hashring.json` which instructs the distibutor what tenants should be sent to which receiver.

Example File:
```json
[
    {
        "hashring": "hashring0",
        "tenants": ["high_volume_tenant_1", "tenant_b"],
        "endpoints": ["thanos-high-volume-receiver-1:10901"]
    },
    {
        "hashring": "hashring1",
        "tenants": [],
        "endpoints": ["thanos-catchall-receiver-1:10901"]
    }
]
```

It works on a first match basis. In the above example `tenant_b` would match `hashring0`, while any tenants not matching will end up in the `hashring1` (Empty tenants list == unlimited).

The hashring config file is updated automatically be the [receive-controller](#receive-controller).

#### Receive (Ingester)

The receive ingester is the statefulset responsible for persistening the write requests to disks.
It also replicates data based on the set replication factor, to ensure data availability in the event a pod goes down.
Much like other components in thanos that receive or write data, it uploads on a 2 hour interval (by default) to our long term storage bucket.

#### Receive Controller

The receive controller helps with discoverability and scalability of receive ingester pods, and updates the distributor as needed.
It does this by looking up the k8s api and discovering the provisioned pods in a given statefulset.
When changes are detected it updates the `hashring.json` config and updates an annotation on the receive distributor to force an immediate re-read of the mounted config.

This enables us to scale out the ingester statefulsets automatically based on load at a given period.

## Configuring Tenants

We leverage tenants in thanos to help identitfy the origin of metrics, as well as provide limits/quotas to given teams or environments.
Tenants for Thanos Receive are configured in two parts:

1. An entry for the tenant and limits in [k8s-workloads](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-helmfiles/-/blob/master/releases/thanos/ops.yaml.gotmpl#L22)
2. Tenant Credentials in [Vault](https://vault.gitlab.net/ui/vault/secrets/k8s/show/env/ops/ns/thanos/htpasswd)

After you have set up the tenant, you can give the auth credentials and the Thanos receive endpoint URL to the team. Here is a
[example config](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/main/manifests/prometheus/values-ai-assist.yaml)
from Code Suggestions.

Note that the current usage of htpasswd/basicAuth will be replaced in a future iteration.

## Scaling

All components in the receive service are built with autoscaling via kubernetes HPA.
Both nginx and the receive distirbutor and deployments and scale normally based on the HPAs configured thresholds.

The receive ingester however is a statefulset, and while it a stateful workload, we are able to scale this as well via an HPA leveraging the [thanos-controller](#receive-controller).

## Monitoring of Receive

We have implemented initial rules to notify us when a tenant is approaching thier quotes in the
[rules config for the Receive deployment](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-helmfiles/-/blob/master/releases/thanos/ops.yaml.gotmpl#L331).  This will post to the Observability Team's slack channel.

## Troubleshooting

#### Prometheus Remote Write 429 Errors

We enforce limits for tenants in thanos. 429s indicate rate limiting on the client side.
If this is seen from a prometheus client:

- Check the dashboard to validate a tenant has reached its limit [here](https://dashboards.gitlab.net/d/916a852b00ccc5ed81056644718fa4fb/thanos-thanos-receive?orgId=1&refresh=5m).
- Validate no drastic changes in the given prometheus client workload.
- If required increase tenant [limits](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-helmfiles/-/blob/master/releases/thanos/ops.yaml.gotmpl#L22).

Before increasing limits, it's important we ensure that the given tenants increase in metrics is valid and required.
This is a good opportunity to look into un-used metrics and potential cardinality explosions.
If possible we should encourge dropping metrics that are not in use, before increasing the setl imits.

#### Remote Write requests failing

Likely resuting in 500 errors, we have a few things we can check on.

- Ensure the nginx pods are running and processing requests.
- Make sure the receive distributor pods are running.
- Check the receive statefulset pods are running and have quorum. We use a replication of 3, so we must have 2 pods at any given time.
- Lastly ensure the generated config matches the state of the active receivers `kubectl -n thanos get cm thanos-thanos-stack-tenants-generated -o yaml`.
