<!-- Permit linking to GitLab docs and issues -->
<!-- markdownlint-disable MD034 -->
# Cloud Connector

Cloud Connector is a way to access services common to multiple GitLab deployments, instances, and cells.
Cloud Connector is not a dedicated service itself, but rather a collection of APIs, code and configuration
that standardize the approach to authentication and authorization when integrating Cloud services with a GitLab instance.

This document contains general information on how Cloud Connector components are configured and operated by GitLab Inc.
The intended audience is GitLab engineers and SREs who have to change configuration for or triage issues with these
components.

See [Cloud Connector architecture](https://docs.gitlab.com/ee/development/cloud_connector/architecture.html) for more information.

**Table of Contents**

[TOC]

---

## Cloudflare

Any client consuming a Cloud Connector service must do so through `cloud.gitlab.com`, a public endpoint
managed by Cloudflare. A "client" here is either a GitLab instance or an end-user application such as an IDE.

Cloudflare performs the following primary tasks for us:

- Global load balancing using Cloudflare's Anycast network
- Enforcing WAF and other security rules such as rate limiting
- Routing requests into GitLab feature backends

The `cloud.gitlab.com` DNS record is fully managed by Cloudflare, i.e. Cloudflare acts as a [reverse proxy](https://www.cloudflare.com/learning/cdn/glossary/reverse-proxy).
This means any client dialing this endpoint will reach a Cloudflare server, not a GitLab backend.
See [routing](#routing) for more information on how how requests are forwarded.

Routing and rate limits are configured here:

- [staging](https://ops.gitlab.net/gitlab-com/gl-infra/config-mgmt/-/tree/main/environments/cloud-connect-stg)
- [production](https://ops.gitlab.net/gitlab-com/gl-infra/config-mgmt/-/tree/main/environments/cloud-connect-prd)

The default URL for the Cloudflare proxy is `cloud.gitlab.com`, which is used in production environments.
It can be overridden by setting the `CLOUD_CONNECTOR_BASE_URL` environment variable.
For example, we set this to [cloud.staging.gitlab.com](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-com/-/blob/e1354607d4214b1e8b74b9a13126f42136fd712c/releases/gitlab/values/gstg.yaml.gotmpl#L472) for our multi-tenant GitLab
SaaS deployment.
This will direct any Cloud Connector traffic originating from `staging.gitlab.com` to `cloud.staging.gitlab.com`.
Self-managed customers are _not_ expected to set this variable.

### Monitoring

#### Dashboards

- [Cloudflare dashboard](https://dash.cloudflare.com/852e9d53d0f8adbd9205389356f2303d/cloud.gitlab.com)
- [Grafana Cloudflare dashboard for `cloud_gitlab_zone`](https://dashboards.gitlab.net/d/cloudflare-main/cloudflare3a-overview)

#### Alerts

- [CloudflareCloudConnectorRateLimitExhaustion](./alerts/CloudflareCloudConnectorRateLimitEvents.md)

#### Logs

There are three ways to monitor traffic going through `cloud.gitlab.com`, each with their pros and cons:

- [Instant Logs](https://dash.cloudflare.com/852e9d53d0f8adbd9205389356f2303d/cloud.gitlab.com/analytics/instant-logs).
  Use this to monitor live traffic. This stream will only display the most basic properties of an HTTP request,
  such as method and path, but can be useful to filter and monitor traffic on-the-fly.
- [Log Explorer](https://dash.cloudflare.com/852e9d53d0f8adbd9205389356f2303d/cloud.gitlab.com/analytics/log-explorer).
  This tool allows querying historic logs using an SQL-like query language. It can surface all available information
  about HTTP requests, but has limited filtering capabilities. For example, since HTTP header fields are stored as
  an embedded JSON string, you cannot correlate log records with backend logs by filtering on e.g. correlation IDs.
- [LogPush](../cloudflare/logging.md). This approach first pushes logs from Cloudflare to a Google Cloud Storage bucket, from which you can then
  stream these files to your machine as JSON, or load them into BigQuery for further analysis. To stream the last 30m
  of HTTP request logs from a given timestamp into `jq`, run:

  ```shell
  scripts/cloudflare_logs.sh -e cloud-connect-prd -d 2024-09-25T00:00 -t http -b 30 | jq .
  ```

If you wish to correlate log events between Cloudflare logs and the Rails application or Cloud Connector backends:

- **Via request correlation IDs:** Look for `x-request-id` in the Cloudflare `RequestHeaders` field.
  Correlate it with `correlation_id` in application services.
  This identifies an individual request.
- **Via instance ID:** Look for `x-gitlab-instance-id` in the Cloudflare `RequestHeaders` field.
  Correlate it with `gitlab_instance_id` in application services.
  This identifies an individual GitLab instance (both SM/Dedicated and gitlab.com).
- **Via global user ID:** Look for `x-gitlab-global-user-id` in the Cloudflare `RequestHeaders` field.
  Correlate it with `gitlab_global_user_id` in application services.
  This identifies an individual GitLab end-user (both SM/Dedicated and gitlab.com).
- **Via caller IP:** Look for `ClientIP` in Cloudflare logs.
  Correlate it with `client_ip` (or similar fields) in application services.
  This identifies either a GitLab instance or end-user client such as an IDE from which the
  request originated.

### Routing

While this is not systematically enforced, we require all clients that want to reach Cloud Connector backends
to dial `cloud.gitlab.com` instead of the backends directly. Backends that use a public load balancer such as
GCP Global App LB should use Cloud Armor security policies to reject requests not coming from Cloudflare.

Routing is based on path prefix matching. Every Cloud Connector backend (e.g. the AI gateway) must be connected as
a Cloudflare origin server with such a path prefix. For example, the AI gateway is routed via the `/ai` prefix,
so requests to `cloud.gitlab.com/ai/*` are routed to the AI gateway, with the prefix stripped off (only `*` is forwarded.)

You can see an example of this [here](https://ops.gitlab.net/gitlab-com/gl-infra/config-mgmt/-/blob/30e42e4f36bedb6d65922a4dc68125023f6c2adc/environments/cloud-connect-prd/rules.tf).

### Rate limiting

Cloudflare enforces rate limits for `cloud.gitlab.com` to guard against malicious or misbehaving customer instances and clients.
These rate limits are not to be confused with [gitlab.com Cloudflare rate limits](https://ops.gitlab.net/gitlab-com/gl-infra/config-mgmt/-/blob/7c37d9cd6340840b795bf1e44912ba4ef2cc0f2f/environments/gprd/cloudflare-rate-limits-waf-and-rules.tf)
(which guard the gitlab.com application deployment) or [application rate limits](https://docs.gitlab.com/ee/security/rate_limits.html) enforced in the Rails monolith itself.

Cloud Connector rate limits are instead enforced between either customer Rails instance (or end-user) and GitLab backend services.
The following diagram illustrates where Cloud Connector rate limits fit into the overall rate limit setup, for
the example of the AI gateway:

```mermaid
flowchart LR
    user(End-user request\nfrom IDE or web UI) --> is_dotcom

    is_dotcom{GitLab.com?} -- Y --> is_comda
    is_comda{Direct Access?} -- Y --> ccwaf
    is_comda{Direct Access?} -- N --> comwaf
    comwaf{{Cloudflare WAF / gitlab.com}} --> com_rails
    com_rails(GitLab.com Rails app /\nenforces in-app RLs /\GitLab Inc. controls these) --> ccwaf

    is_dotcom{GitLab.com?} -- N --> is_smda
    is_smda{Direct Access?} -- Y --> ccwaf
    is_smda{Direct Access?} -- N --> sm_rails
    ccwaf{{Cloudflare WAF / cloud.gitlab.com}} --> aigw
    sm_rails(Customer Rails app /\nenforces in-app RLs /\nGitLab Inc. can't control these) --> ccwaf

    aigw(AI gateway) --> vendorrl
    vendorrl{{AI vendor limits /\ndifficult to change}} --> aivendor
    aivendor(AI vendor / model)
```

The rate limits enforced in Cloudflare are specified per backend and can be classified as follows.

#### Rate limit events

You can observe WAF events for custom rate limit rules [here](https://dash.cloudflare.com/852e9d53d0f8adbd9205389356f2303d/cloud.gitlab.com/security/events?service=ratelimit).

#### Kinds of rate limits

For all deployments of GitLab (gitlab.com or SM/Dedicated):

- **Per user.** Limits applied to a given user identified by a unique global UID string.
- **Per authentication attempt.** Rate limits applied to clients that produce repeated `401 Unauthorized` server responses.
  This is to prevent credential stuffing and similar attacks that brute force authentication.

For SM/Dedicated only:

- **Per instance.** Rate limits applied to a given SM/Dedicated GitLab instance, regardless
  of which user associated with this instance sent the request. This is to put an overall cap on the amount of traffic
  any customer may send into GitLab infrastructure. The "instance = customer" definition is inaccurate,
  but a decent approximation until there is a better way to map requests to customers (e.g. via `Organization` IDs).

#### Rate limit buckets

Per-user and per-instance rate limits can be further segmented into buckets or tiers.

These buckets are:

- `Any`: Any client that cannot be clearly attributed to a paying GitLab Duo customer.
- `Small/Medium/Large`: Size buckets based on the number of GitLab Duo seats a customer
   purchased, as transmitted through the `X-Gitlab-Duo-Seat-Count` header. These rules
   will therefore only be enacted for paying Duo customers.

This allows us to broadly classify customers into tiers and grant more
lenient limits the more seats they own. For example, a small customer (identified by a small number of add-on seats),
observes stricter rate limits than a large customer.

Any other clients will be lumped together and observe a generic rate limit.

<!-- markdownlint-enable MD034 -->

## Key rotation

Cloud Connector uses JSON Web Tokens to authenticate requests in backends. For multi-tenant customers on gitlab.com,
the Rails application issues and signs these tokens. For single-tenant customers (SM/Dedicated), CustomersDot issues
and signs these tokens. To validate tokens, Cloud Connector backends fetch the corresponding keys from the gitlab.com
and CustomersDot Rails applications respectively.

Keys should be rotated on a 6 month schedule both in staging and production.

### Rotating keys for gitlab.com

Keys must be rotated in staging and production. The general steps in both environments are:

1. Run `sudo gitlab-rake cloud_connector:keys:list` to verify there is exactly one key.
1. Run `sudo gitlab-rake cloud_connector:keys:create` to add a new key to rotate to.
1. Run `sudo gitlab-rake cloud_connector:keys:list` to verify there are exactly two keys.
1. Ensure validators have fetched the new key via OIDC Discovery.
   Depending on the particular system, this may involve:
   - Wait at least 24 hours or longer, depending on how long keys are cached for.
   - Restart the system or otherwise evict its key cache.
   - For the AI Gateway only, ensure [this dashboard](https://log.gprd.gitlab.net/app/r/s/p7Rhe) shows no events.
1. Run `sudo gitlab-rake cloud_connector:keys:rotate` to swap current key with new key, enacting the rotation.
1. Monitor affected systems to still work as intended (failure would surface as 401s).
1. Run `sudo gitlab-rake cloud_connector:keys:trim` to remove the now unused key.
1. Monitor affected systems to still work as intended (failure would surface as 401s).

#### Rotating keys in staging

1. Run `/change declare` in Slack and create a C3 [Change Request](https://handbook.gitlab.com/handbook/engineering/infrastructure/change-management/).
1. Teleport to `console-01-sv-gstg`.
1. Run steps outlined [above](#rotating-keys-for-gitlabcom).
1. Close the CR issue.

#### Rotating keys in production

1. Run `/change declare` in Slack and create a C2 [Change Request](https://handbook.gitlab.com/handbook/engineering/infrastructure/change-management/).
1. Teleport to `console-01-sv-gprd`.
1. Run steps outlined [above](#rotating-keys-for-gitlabcom).
1. Close the CR issue.
1. Create a Slack reminder in `#g_cloud_connector` set to 6 months from now with a link to this runbook.

### Rotating keys for customers.gitlab.com

Follow instructions [here](https://gitlab.com/gitlab-org/customers-gitlab-com/-/blob/main/doc/security/jwk_signing_key_rotation.md).
