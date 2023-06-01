# Thanos Receive

Docs: <https://thanos.io/tip/components/receive.md/>

Thanos Receive implements a remote write endpoint for Prometheus.  We are using it to more easily ingest metrics from various projects.

The receivers[run in ops](https://gitlab.com/gitlab-com/gl-infra/readiness/-/blob/master/thanos/overview.md) and are deployed by
[k8s-workdloads helm charts](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-helmfiles/-/tree/master/releases/thanos/receivers).  

### Configuring Tenants 

Tenants for Thanos Receive are configured in two parts:
1. An entry for the tenant and limits in [k8s-workloads](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-helmfiles/-/blob/master/releases/thanos/ops.yaml.gotmpl#L22)
2. Tenant Credentials in [Vault](https://vault.gitlab.net/ui/vault/secrets/k8s/show/env/ops/ns/thanos/htpasswd)

After you have set up the tenant, you can give the auth credentials and the Thanos receive endpoint URL to the team.

[Example config](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/main/manifests/prometheus/values-ai-assist.yaml) 
from Code Suggestions

### Monitoring of Receive

We have implemented initial rules to notify us when a tenant is approaching thier quotes in the 
[rules config for the Receive deployment](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-helmfiles/-/blob/master/releases/thanos/ops.yaml.gotmpl#L331).  This will post to the Observability Team's slack channel.


