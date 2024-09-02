## Overview of Rate Limits for <https://gitlab.com>

**Table of Contents**

[TOC]

## Updated Documentation

The handbook is the new source of truth for [Rate Limiting information](https://handbook.gitlab.com/handbook/engineering/infrastructure/rate-limiting/).

If you are looking for information about requesting a rate limit bypass for GitLab.com, please see the [Rate Limit bypass policy](bypass-policy.md).

## Bypasses and Special Cases

This section of documentation is targeted for SREs working in the production environment.

[Published rate limits](https://docs.gitlab.com/ee/user/gitlab_com/index.html#gitlabcom-specific-rate-limits) apply to all customers and users with no exceptions. Rate limiting bypasses are only allowed for specific cases:

We need special handling for various partners and other scenarios (e.g. excluding GitLab's internal services).
To permit this we have lists of IP addresses, termed `allowlist` that are permitted to bypass the haproxy rate limit.

Trusted IPs from customers/partners can be added to the second list, in `gitlab-haproxy.frontend.allowlist.api` which allows
for comments/attribution. However, we would prefer to whittle this list _down_, not add to it, so before doing so
engage with the customer (via their TAM, probably) and endeavour to find a way to achieve their goals more efficiently.
This may require development work to enhance the API, or often webhooks (to add more information so that it can be
pushed to the customer, rather than polled), but this is likely well worth it (in some cases simply adding a couple of
fields to a webhook has eliminated the need for many API calls).

If adding a customers IPs to this list becomes unavoidable due to an incident or temporary urgent customer need,
create a (usually confidential) issue using the
[request-rate-limiting](https://gitlab.com/gitlab-com/gl-infra/reliability/-/issues/new?issuable_template=request-rate-limiting)
issue template discussing the justification and what steps have been taken to avoid doing so (or what could be done).
Temporary bypass requests should include the date or time at which the bypass can be lifted so we do not leave it in place indefinitely.
Customers who already have IPs in the list can be assumed to have a legacy grant and may have IPs added as necessary, as
long as it looks reasonable (e.g. adding a few more where there are already many; questions should be asked if they ask
to add 100 when they currently have 2). Note also (see the RackAttack section below) that we somewhat prefer
user-specific bypasses rather than IP address bypasses, where practical.

It is also worth noting that requests from IPs given this bypass treatment also have the X-GitLab-RateLimit-Bypass
header set to 1, which RackAttack (see below) interprets to mean they get a bypass there as well. This is a
sort-of-temporary measure, to allow us to enable the RackAttack rate-limiting without having to solve every high-usage
use-case before doing so. Ideally we will remove this eventually, once the bypass list is smaller (or gone), or we've
ensured that our known users are below the new limits.

There are a few other special cases that also set `X-GitLab-RateLimit-Bypass`; this may change over time, but at this time
includes git-over-https, `/jwt/auth`, various package registries (e.g. maven, nuget, composer compatibility APIs), and
requests with `?go_get=1`. The full list, which should include links to the justification issue for each exception,
is [here](https://gitlab.com/gitlab-cookbooks/gitlab-haproxy/-/blob/master/templates/default/frontends/https.erb#L49).

Speaking of the package registries in particular, these have a much higher limit. See
<https://gitlab.com/gitlab-com/gl-infra/reliability/-/issues/11748> for a full discussion of this, but in short, the
endpoints are fairly cheap to process _and_ are often hit fairly hard by deployment/build processes, and we have to
support that. It's not out of the question that the architecture of this may change in future. The others are a bit
more special-case (and a bit less interesting) and the justifications won't be repeated here.

For the avoidance of doubt: we set `X-GitLab-RateLimit-Bypass` to `0` by default; any value for this in the client request
is overwritten.

See also related docs in [../frontend](../frontend/) for other information on blocking and HAProxy config.

Link any bypasses created to <https://gitlab.com/groups/gitlab-com/gl-infra/-/epics/374> so that we can track it to completion.
These are _never_ permanent, they are only stepping stones to making the API better or otherwise enhancing the product to eliminate
the excessive traffic. In practice what we have found so far is issues like webhooks payloads lacking trivial details that
must then be scraped/polled from the API instead, and so on.

Finally, and importantly, there is a moderate preference for a user-based bypass over an IP-address based one, because
as noted above, an IP address is a poor proxy for actual identity. Not only could there be more than one person behind
a single IP address (including some we may not trust as much), but IP addresses aren't anywhere near as static as people
often assume, and they can move/change sometimes without notice (or awareness), can 'rot' where they are no longer in
use by the original user but we're not informed, and so on. User ids are much less fungible, and carry implications of
paid groups/users and permanent identities of customers.

### Implementing Approved Bypasses

For customers and internal teams seeking a bypass, please refer to the [Rate Limit bypass policy](bypass-policy.md). This section of documentation is targeted for SREs working in the production environment.

To add an IP to the RackAttack allowlist:

- Create a new version of the vault secret at
  <https://vault.gitlab.net/ui/vault/secrets/shared/show/env/gprd/gitlab/rack-attack>
  to append the desired IPs
- Create a MR to bump the secret in our k8s deployment to your new version. Example MR:
  <https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-com/-/merge_requests/3057>
- Create a MR to remove the old secret version from our k8s deployment. Example MR:
  <https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-com/-/merge_requests/3058>

Anytime an IP is added to the allowlist, an issue for removing the IP should be [opened in the production engineering tracker](https://gitlab.com/gitlab-com/gl-infra/production-engineering/-/issues/new) cross-linking the original issue or incident where the IP was added and setting a due date for the IPs to be removed. In the case of allow-list requests, this is at most 2 weeks after the IP was added.

### HaProxy

HAProxy is responsible for handling the `X-GitLab-Rate-Limit-Bypass` header. This header allows for a configured list of IP addresses to bypass rate limits.

## Application (RackAttack)

It is possible to enable RackAttack rate limiting rules in "Dry Run" mode which can be utilised when introducing new rate limits by setting the `GITLAB_THROTTLE_DRY_RUN` environment variable with the name of the new rule in a running Rails process.

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
