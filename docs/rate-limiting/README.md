## Overview of Rate Limits for <https://gitlab.com>

**Table of Contents**

[TOC]

The handbook is the source of truth for [Rate Limiting information](https://handbook.gitlab.com/handbook/engineering/infrastructure/rate-limiting/).

If you are looking for information about requesting a rate limit bypass for GitLab.com, please see the
[Rate Limit bypass policy](https://handbook.gitlab.com/handbook/engineering/infrastructure/rate-limiting/bypass-policy/).

This section of documentation is targeted at SREs working in the production environment.

## Bypasses and Special Cases

[Published rate limits](https://docs.gitlab.com/ee/user/gitlab_com/index.html#gitlabcom-specific-rate-limits) apply to
all customers and users with no exceptions. Rate limiting bypasses are only allowed for specific cases.

We need special handling for various partners and other scenarios (e.g. excluding GitLab's internal services).
To permit this we have lists of IP addresses, termed `allowlist` that are permitted to bypass the rate limits.

Trusted IPs from customers/partners can be added to the allowlists, however we'd prefer to whittle this list _down_,
not add to it. The [Rate Limit bypass policy](https://handbook.gitlab.com/handbook/engineering/infrastructure/rate-limiting/bypass-policy/)
must be followed when considering adding to these lists.

- **Cloudflare**
  - Deprecated approach: [cf_rate_bypass_ips](https://ops.gitlab.net/gitlab-com/gl-infra/config-mgmt/-/blob/main/environments/gprd/cloudflare-rate-limits-waf-and-rules.tf#L12-33) (confidential)
  - Custom rule bypass: [example](https://ops.gitlab.net/gitlab-com/gl-infra/config-mgmt/-/blob/main/environments/gprd/cloudflare-custom-rules.tf#L156) (confidential)
- **HAProxy**
  - [rate_limit_allowlist](https://gitlab.com/gitlab-com/gl-infra/chef-repo/-/blob/master/roles/gprd-base-haproxy-main-config.json?ref_type=heads#L176)

User-based bypasses are preferred over IP based, as IP addresses are a poor proxy for actual identity.
User IDs are much less fungible, and carry implications of paid gruops/users and permanent identities of customers,
whereas there could be multiple users behind a single IP address and these can `rot` if they are no longer used by the
original user.

### Steps to follow before implementing a bypass

- Engage with the customer (via their TAM) and endeavour to find a way to achieve their goals without bypasses.
- May require development to enhance the API or webhooks (add more information so it can be pushed to the customer, rather than polled).
- In some cases, adding a couple of fields to a webhook can eliminate the need for many API calls.
- If implementing a bypass is unavoidable due to incident or temporary urgent customer need then follow the steps listed in the [bypass policy](https://handbook.gitlab.com/handbook/engineering/infrastructure/rate-limiting/bypass-policy/#process-to-request-a-bypass)

Customers with IPs present in the allow list can be assumed to have legacy grant and may have IPs added as necessary,
as long as the ask is reasonable (e.g. adding a few more where there are already many; questions should be asked if they ask
to add 100 when they currently have 2).

### Bypass headers

The `X-GitLab-RateLimit-Bypass` header is set to `0` by default. Any value set for this by the client request is overwritten.

Requests from IPs with a bypass configured will have the `X-GitLab-RateLimit-Bypass` header set to 1, which RackAttack
interprets to mean these requests bypass the rate limits. Ideally we will remove this eventually, once the bypass list
is smaller (or gone), or we've ensured that our known users are below the new limits.

There are a few other special cases that also set `X-GitLab-RateLimit-Bypass`; The full list, which should include links
to the justification issue for each exception, is [here](https://gitlab.com/gitlab-cookbooks/gitlab-haproxy/-/blob/master/templates/default/frontends/https.erb#L49).

See also related docs in [../frontend](../frontend/) for other information on blocking and HAProxy config.

### Tracking Bypasses

Link any bypasses created to <https://gitlab.com/groups/gitlab-com/gl-infra/-/epics/374> so that we can track it to completion.

These are _never_ permanent, they are only stepping stones to making the API better or otherwise enhancing the product to eliminate
the excessive traffic. In practice what we have found so far is issues like webhooks payloads lacking trivial details that
must then be scraped/polled from the API instead, and so on.

Anytime an IP is added to the allowlist, an issue for removing the IP should be [opened in the production engineering tracker](https://gitlab.com/gitlab-com/gl-infra/production-engineering/-/issues/new) cross-linking the original issue or incident where the IP was added and setting a due date for the IPs to be removed. In the case of allow-list requests, this is **at most** 2 weeks after the IP was added.

### Implementing Approved Bypasses in Cloudflare

**Note:** Cloudflare has higher limits than RackAttack, proceed with extra caution if the decision has been made to implement a bypass at this layer.

To add a new entry to the Cloudflare allowlist:

- Create a new custom rule in `config-mgmt`, similar to: [this bypass](https://ops.gitlab.net/gitlab-com/gl-infra/config-mgmt/-/blob/dcf17ff7d43665039167b0f1bde1fc90cb46ba41/environments/gprd/cloudflare-custom-rules.tf#L165-184)

### Implementing Approved Bypasses in Rack Attack

To add an IP to the RackAttack allowlist:

- Create a new version of the vault secret at
  <https://vault.gitlab.net/ui/vault/secrets/shared/show/env/gprd/gitlab/rack-attack>
  to append the desired IPs
- Create a MR to bump the secret in our k8s deployment to your new version. Example MR:
  <https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-com/-/merge_requests/3057>
- Create a MR to remove the old secret version from our k8s deployment. Example MR:
  <https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-com/-/merge_requests/3058>

### HAProxy

HAProxy is responsible for handling the `X-GitLab-Rate-Limit-Bypass` header. This header allows for a configured list of IP addresses to bypass rate limits.

## Application (RackAttack)

### Enable an Application Rate Limit in "Dry Run" mode

It is possible to enable RackAttack rate limiting rules in "Dry Run" mode
which can be utilised when introducing new rate limits
by setting the `GITLAB_THROTTLE_DRY_RUN` environment variable
[[source]](https://docs.gitlab.com/ee/administration/settings/user_and_ip_rate_limits.html#try-out-throttling-settings-before-enforcing-them).

For `GitLab.com` these environment variables are managed in k8s-workloads,
and set in the [extraEnv](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-com/-/blob/donna/dry-run-authenticated-rate-limits/releases/gitlab/values/gprd.yaml.gotmpl?ref_type=heads#L359).

Once the `GITLAB_THROTTLE_DRY_RUN` environment variable is configured in production,
you can then turn the specified throttle on, for example `throttle_authenticated_web`.
If the new limit that is being introduced is hit,
you should see `event_type="track"` in the RackAttack metrics and logs.

After validating the rate limit threshold is behaving as expected,
you should remove the event name from the `GITLAB_THROTTLE_DRY_RUN` environment variable
which will allow the rate limit to start throttling requests.

- [Metrics: RackAttack events by event name and type](https://dashboards.gitlab.net/goto/XVO2kVvNg?orgId=1)


## How-Tos

So you're faced with some sort of urgent issue related to rate-limiting. What are your basic options?

1. If you've got a small number of URLs (perhaps just one) that need severe rate-limiting (e.g. a specific repo, MR,
   issue etc), use CloudFlare rate-limiting:
   <https://ops.gitlab.net/gitlab-com/gitlab-com-infrastructure/-/blob/master/environments/gprd/cloudflare-waf.tf>
   - This would usually be a response to an incident, probably performance/apdex related where we just need breathing
   room while we clean things up, or while a code fix is prepared, and we're keeping the site alive.
   - Work with an IMOC or a peer to validate the change is reasonable and correct \* These will typically be temporary; anything permanent needs more careful discussion
1. A user/bot is having serious difficulties because they're being rate-limited. After ensuring that
   there's no better way to solve their problem,
   - Decide if it needs to be a user-based bypass (preferred) implemented in Rails via the environment variable, or an
     IP-address based bypass (less preferred) configured in haproxy.
   - Raise a [rate-limiting issue](https://gitlab.com/gitlab-com/gl-infra/reliability/-/issues/new?issuable_template=request-rate-limiting)
   - Get consensus/approval from some peers or managers that there's no other option (on the rate-limiting issue)
   - Establish what layer is the rate-limiting happening. Search for the affected IPs in the following links:
     - Cloudflare: <https://dash.cloudflare.com/852e9d53d0f8adbd9205389356f2303d/gitlab.com/analytics/traffic?client-ip~in=ip1%2Cip2>
     - HAProxy: <https://console.cloud.google.com/bigquery?sq=805818759045:1e5b45317ecd453ba6cc33818451f76f>
     - RackAttack: <https://log.gprd.gitlab.net/app/r/s/oxJCB>
   - Look for the "Bypasses" section on the relevant component on this page for instructions on implementing a rate-limit exception
   - Leave the issue open, linked to <https://gitlab.com/groups/gitlab-com/gl-infra/-/epics/374> for tracking and so we
     can try to make things better
1. One endpoint (or related collection of endpoints) is being unduly rate-limited and we can safely increase the limit for them. This is the same situation as the Package Registry exceptions, and there are two options:
   1. If time is of the essence, implement the increased rate-limit and set the bypass header in haproxy, as is done for the Package Registry. This allows haproxy to be the arbiter of the rate-limit, but by IP address only.
   1. If time allows, prefer a custom RackAttack limit, particularly if it should take into account user-identity, not just IP address. This is more flexible long term and is then usable by self-managed deployments, but may take a bit longer to be fully implemented and deployed as it requires work on the main GitLab codebase.
1. The values of the rate-limits are all wrong, and need to be raised
   - Take a deep breath. This is a serious choice, and you need to be really certain. The values have been chosen
     carefully, and perhaps adjusted carefully over time. Do Not Rush.
   - Consider other options, such as special-case rate-limits in RackAttack, or setting the X-GitLab-RateLimit-Bypass
     header to 1 in haproxy for _specific_ requests (URL patterns or other identifiers) to solve the immediate problem
     without causing wider damage.
   - Gather evidence (logs usually) of what is going on and why the limits are wrong, in a discussion issue in the
     infrastructure tracker, and get eyes on it. Include at least the Infrastructure PM (Andrew Thomas), Director of
     Infrastructure (Brent Newton) and Marin Jankovski. The Scalability team may also be able to help, although they're
     not the arbiters just interested onlookers with some experience in this area.
   - Read the other context in this document, including any constraints on values like the period, or matching values
     between haproxy and RackAttack.
   - Verify that the proposed increase is able to be absorbed by our existing infrastructure, or that we can scale the
     infrastructure up sufficiently to support it. Consider database, gitaly, and redis, as well as front-end compute.
   - If it is agreed to proceed, raise a production change issue, linked to the earlier discussion issue, to execute the
     change.
   - Ensure <https://gitlab.com/gitlab-org/gitlab/-/tree/master/doc/user/gitlab_com/#gitlabcom-specific-rate-limits> is
     updated to match the new values
