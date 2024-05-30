# Accessing and Using CloudFlare

**Table of Contents**

[TOC]

Users that have been provisioned can access Cloudflare directly at
`https://dash.cloudflare.com`.

## Instructions for Access Provisioners

**IT:**

1. Add the user to the `okta-cloudflare-users` Google group.
1. Ping `@gitlab-org/production-engineering/foundations` to privision the Cloudflare role

**Foundations**

1. Open a merge request adding the user to <https://ops.gitlab.net/gitlab-com/gl-infra/config-mgmt/-/blob/main/environments/cloudflare/users.tf>
   1. Assign the role based on the access request or baseline entitlements (SREs receive Administrator acess as baseline).
1. The user will automatically receive an invite once the change is applied.
   1. If the user does not accept the invite before expiration, a state drift will occur and the change will need to be applied again.

# Configuraion

## Creating or Editing Custom Rules

TODO: link to terraform module

### Managing Traffic (blocks and allowlists)

[Cloudflare: Managing Traffic](./cloudflare-managing-traffic.md)

## Anti-Abuse Investigations

TODO: List some common things to filter on in the Firewall tab.

## Managing Workers

Interim documentation: <https://ops.gitlab.net/gitlab-com/gl-infra/terraform-modules/cloudflare_workers#configuration>

# Getting support from Cloudflare

## Contacting support

## Contact Numbers

Should we need to call Cloudflare, we were given these numbers to reach out to for help.

Those numbers are documented in <https://gitlab.com/gitlab-com/gl-security/runbooks/-/blob/master/sirt/infrastructure/cloudflare.md>

# Other References

## Implementation Epic

<https://gitlab.com/groups/gitlab-com/gl-infra/-/epics/94>

## Readiness review

<https://gitlab.com/gitlab-com/gl-infra/readiness/blob/master/cloudflare/README.md>

## Issue Tracker for Evaluation

**Cloudflare Vendor Tracker**: <https://gitlab.com/gitlab-com/gl-infra/cloudflare/issues>
