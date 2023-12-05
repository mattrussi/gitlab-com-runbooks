<!-- MARKER: do not edit this section directly. Edit services/service-catalog.yml then run scripts/generate-docs -->

**Table of Contents**

[[_TOC_]]

# Loki Service

* **Alerts**: <https://alerts.gitlab.net/#/alerts?filter=%7Btype%3D%22loki%22%2C%20tier%3D%22inf%22%7D>
* **Label**: gitlab-com/gl-infra/production~"Service::Loki"

## Logging

* []()

<!-- END_MARKER -->

### Tenant Provisioning

Tenant provisioning is currently handled by the [tenant-provisioner](https://gitlab.com/gitlab-com/gl-infra/sre-observability/tenant-provisioner), its a very simple service thats essentially a hosted shell script. You can use it like this:

```
curl -X POST --header "Authorization: $VAULT_TOKEN" --data '{ "name": "TENANT_NAME" }' https://observability-gateway.ops.gke.gitlab.net/tenants
```

It'll return the tenant credentials on a successful request, otherwise a 500 in all other cases; The new credentials are also written to
`shared/observability-tenants/{TENANT_NAME}` in vault, this value is b64 encoded.
