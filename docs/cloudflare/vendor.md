# Accessing and Using CloudFlare

Users that have been provisioned can access Cloudflare directly at
`https://dash.cloudflare.com`.

## Baseline Entitlements and Provisioning

CloudFlare Administrator Access is a baseline entitlement for SRE.

Instructions for Access Provisioners (requires Super Administrator privileges):

1. Log in to the dashboard at <https://dash.cloudflare.com>.
2. Navigate to the "GitLab" account.
3. Select the "Members" tab.
4. Select the permission level. Be user to unselect "Administrator" when selecting
   "Administrator Read Only", it is not automatically unselected.
5. Enter the team members emails and click "Invite".

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
