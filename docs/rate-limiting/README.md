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
  - Custom rule bypass: [example](https://ops.gitlab.net/gitlab-com/gl-infra/config-mgmt/-/blob/main/environments/gprd/cloudflare-custom-rules.tf#L156) (confidential)

User-based bypasses are preferred over IP based, as IP addresses are a poor proxy for actual identity.
User IDs are much less fungible, and carry implications of paid groups/users and permanent identities of customers,
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

The `X-GitLab-RateLimit-Bypass` header is set to `0` by default. Any value set for this by the client request is overwritten by Cloudflare.

Requests from IPs with a bypass configured will have the `X-GitLab-RateLimit-Bypass` header set to 1, which RackAttack
interprets to mean these requests bypass the rate limits. Ideally we will remove this eventually, once the bypass list
is smaller (or gone), or we've ensured that our known users are below the new limits.

There are a few other special cases that also set `X-GitLab-RateLimit-Bypass` - these are primarily internal infrastructure addresses such as runner managers, or 3rd party vendors who have integrations with us.

All current bypasses are implemented [here](https://ops.gitlab.net/gitlab-com/gl-infra/config-mgmt/-/blob/main/environments/gprd/cloudflare-custom-rules.tf).

### Tracking Bypasses

Link any bypasses created to <https://gitlab.com/groups/gitlab-com/gl-infra/-/epics/374> so that we can track it to completion.

These are _never_ permanent, they are only stepping stones to making the API better or otherwise enhancing the product to eliminate
the excessive traffic. In practice what we have found so far is issues like webhooks payloads lacking trivial details that
must then be scraped/polled from the API instead, and so on.

Anytime an IP is added to the allowlist, an issue for removing the IP should be [opened in the production engineering tracker](https://gitlab.com/gitlab-com/gl-infra/production-engineering/-/issues/new) cross-linking the original issue or incident where the IP was added and setting a due date for the IPs to be removed. In the case of allow-list requests, this is **at most** 2 weeks after the IP was added.

### Implementing Bypasses

#### Cloudflare (IP-based)

Cloudflare is responsible for IP-based rate limiting and bypasses on GitLab.com. **Do not put IP addresses into HAProxy or RackAttack for allowlisting!**

To add a new entry to the allowlist:

- Create a new variable containing the customer's IP addresses in [this file](https://ops.gitlab.net/gitlab-com/gl-infra/config-mgmt/-/blob/main/environments/gprd/allowlists.tf)
  - Put a link to the rate limiting request issue in the comments so that we can easily attribute the IPs later.
- Add a new custom rule using the variable in [this file](https://ops.gitlab.net/gitlab-com/gl-infra/config-mgmt/-/blob/main/environments/gprd/cloudflare-custom-rules.tf)
  - The custom rule will tell WAF to skip all rate limiting rules for the listed IPs, bypassing them.
- Add a new transform rule using the variable in [this file](https://ops.gitlab.net/gitlab-com/gl-infra/config-mgmt/-/blob/main/environments/gprd/cloudflare-transform-rules.tf)
  - The transform rule will tell Cloudflare to apply the `X-GitLab-RateLimit-Bypass: 1` header for all IPs in the allowlist.

#### Rails (RackAttack)

##### User-based

Per the [docs](https://docs.gitlab.com/ee/administration/settings/user_and_ip_rate_limits.html#allow-specific-users-to-bypass-authenticated-request-rate-limiting), we can designate specific user IDs as being able to bypass authenticated rate limits.

1. Update the Vault secret [here](https://vault.gitlab.net/ui/vault/secrets/shared/kv/env%2Fgprd%2Ffrontend%2Fuser-ratelimit) by appending the user ID to the list.
2. Bump the version of the secret [here](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-com/-/blob/master/releases/gitlab-external-secrets/values/gprd.yaml.gotmpl#L165).
3. Finally, [use the new version](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-com/-/blob/master/releases/gitlab/values/gprd.yaml.gotmpl#L386) of the secret in the Helm chart.

##### IP-based

We previously used to put a list of IPs to be allowlisted into the `/var/opt/gitlab/rack_attack_ip_whitelist/ip_whitelist` file where it would be read by the application. This method is no longer used; you should put the IPs into Cloudflare instead.

## Application (RackAttack)

### Enable an Application Rate Limit in "Dry Run" mode

It is possible to enable RackAttack rate limiting rules in "Dry Run" mode
which can be utilised when introducing new rate limits
by setting the `GITLAB_THROTTLE_DRY_RUN` environment variable
[[source](https://docs.gitlab.com/ee/administration/settings/user_and_ip_rate_limits.html#try-out-throttling-settings-before-enforcing-them)].

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
   - Decide if it needs to be a user-based bypass (preferred) implemented in Rails via the `GITLAB_THROTTLE_USER_ALLOWLIST` environment variable, or an
     IP-address based bypass (less preferred) configured in Cloudflare.
   - Raise a [rate-limiting issue](https://gitlab.com/gitlab-com/gl-infra/reliability/-/issues/new?issuable_template=request-rate-limiting)
   - Get consensus/approval from some peers or managers that there's no other option (on the rate-limiting issue)
   - Establish what layer is the rate-limiting happening. Search for the affected IPs in the following links:
     - Cloudflare: <https://dash.cloudflare.com/852e9d53d0f8adbd9205389356f2303d/gitlab.com/analytics/traffic?client-ip~in=ip1%2Cip2>
     - RackAttack: <https://log.gprd.gitlab.net/app/r/s/oxJCB>
   - Refer to the [Implementing Bypasses](#implementing-bypasses) section for instructions on how to put a new bypass in.
   - Leave the issue open, linked to <https://gitlab.com/groups/gitlab-com/gl-infra/-/epics/374> for tracking and so we
     can try to make things better
2. One endpoint (or related collection of endpoints) is being unduly rate-limited and we can safely increase the limit for them. This is the same situation as the Package Registry exceptions, and there are two options:
   1. If time is of the essence, implement the increased rate-limit and set the bypass header in Cloudflare.
   2. If time allows, prefer a custom RackAttack limit, particularly if it should take into account user-identity, not just IP address. This is more flexible long term and is then usable by self-managed deployments, but may take a bit longer to be fully implemented and deployed as it requires work on the main GitLab codebase.
3. The values of the rate-limits are all wrong, and need to be raised
   - Take a deep breath. This is a serious choice, and you need to be really certain. The values have been chosen
     carefully, and perhaps adjusted carefully over time. Do Not Rush.
   - Consider other options, such as special-case rate-limits in RackAttack, or setting the `X-GitLab-RateLimit-Bypass`
     header to 1 in Cloudflare for _specific_ requests (URL patterns or other identifiers) to solve the immediate problem
     without causing wider damage.
   - Gather evidence (logs usually) of what is going on and why the limits are wrong, in a discussion issue in the
     infrastructure tracker, and get eyes on it. Include at least the SaaS Platforms PM Sam Wiskow (`@swiskow`), senior manager of Production Engineering Rachel Nienaber (`@rnienaber`) and manager of Production Engineering Foundations Steve Abrams (`@sabrams`).
   - Verify that the proposed increase is able to be absorbed by our existing infrastructure, or that we can scale the
     infrastructure up sufficiently to support it. Consider database, Gitaly, and Redis, as well as front-end compute.
   - If it is agreed to proceed, raise a production change issue, linked to the earlier discussion issue, to execute the
     change.
   - Ensure <https://gitlab.com/gitlab-org/gitlab/-/tree/master/doc/user/gitlab_com/#gitlabcom-specific-rate-limits> is
     updated to match the new values
