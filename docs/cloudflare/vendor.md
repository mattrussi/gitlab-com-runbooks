# Accessing and Using CloudFlare

**Table of Contents**

[TOC]

Users that have been provisioned can access Cloudflare directly at
`https://dash.cloudflare.com`.

## Instructions for Access Provisioners

1. Ping `@sabrams` or `@pguinoiseau` to add the user to the `okta-cloudflare-users` [Google group](https://groups.google.com/a/gitlab.com/g/okta-cloudflare-users/members). If they are unavailable, IT can help provision this piece. You can reach out to IT using the [#it_help](https://gitlab.enterprise.slack.com/archives/CK4EQH50E) channel or tagging `@gitlab-com/gl-security/corp/helpdesk` in the issue.
1. If the team member needs to be added to the GitLab.com Cloudflare account: (usually Production Engineering or Scalability SREs)
   1. Open a merge request adding the user to <https://ops.gitlab.net/gitlab-com/gl-infra/config-mgmt/-/blob/main/environments/cloudflare/users.tf>
      1. Assign the role based on the access request or baseline entitlements (SREs receive Administrator access as baseline).
   1. The user will automatically receive an invite once the change is applied.
      1. If the user does not accept the invite before expiration, a state drift will occur and the change will need to be applied again.
1. If the team member should be added to the Dedicated Cloudflare accounts (for SREs on the Dedicated Teams), they should open an MR against the [Dedicated Cloudflare Organization](https://gitlab.com/gitlab-com/gl-infra/gitlab-dedicated/dedicated-organization-cloudflare) project

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
