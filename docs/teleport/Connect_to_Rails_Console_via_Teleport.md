# Connecting To a Rails Console via Teleport

**Table of Contents**

[TOC]

## Background on Teleport

Rails consoles in `gprd`, `gstg`, and other environments are accessed via [Teleport](https://goteleport.com/teleport/docs/).
Access to Rails consoles by SSH'ing into the console servers will be removed in future (for the majority of use cases).

- The main reasons for this change are security and compliance:
  With Teleport we have fully flexible, on-demand, and audited access to our Rails consoles and to some other terminal/CLI tools,
  like `kubectl`, [Database access via psql](Connect_to_Database_Console_via_Teleport.md) and more.
- Teleport's goal is to provide a *Unified Access Plane* for all our infrastructure.
  [Here](https://goteleport.com/docs/) you can find some of the most popular use cases for Teleport.
- We evaluated Teleport thoroughly (see this [issue](https://gitlab.com/gitlab-com/gl-infra/reliability/-/issues/11568))
  and found it to comply with most of our infrastructure access requirements,
  unlike some of its competitors ([Okta-ASA](https://gitlab.com/gitlab-com/gl-infra/reliability/-/issues/12042),
  [Hashicorp Boundary](https://gitlab.com/gitlab-com/gl-infra/reliability/-/issues/11666) and others).

## Access Request

Before you start using Teleport, you must be assigned the app in Okta. This should be a part of your role's baseline group assignment.
In most cases there should be no additional action required to gain access to the services appropriate to your role.
If your onboarding is complete and you still do not see the Teleport app listed in Okta, open an
[access request](https://handbook.gitlab.com/handbook/business-technology/end-user-services/onboarding-access-requests/access-requests/)
and follow the appropriate approval methods.

Note that trying to login to the Teleport Console from Okta dashboard can fail with a message "Login Unsuccessful",
this is totally expected and does not mean you need to open an access request.

It is worth noting that if you need to make changes to the production environment,
then declare a change in [#production](https://gitlab.enterprise.slack.com/archives/C101F3796) Slack channel
using the `/change declare` command, after filling the steps and other details, an SRE should be able to execute the change for you.

## Connect To Rails Console

NOTE: we now have only one Teleport instance available at <https://production.teleport.gitlab.net>.

There are two ways to use Teleport for connecting to a Rails console:

1. Installing [tsh](https://goteleport.com/docs/reference/cli/tsh/), the Teleport CLI client. This is the recommended way.
1. Via the [Teleport Web UI](https://production.teleport.gitlab.net/)

### Installing tsh

Official packages for [macOS](https://goteleport.com/docs/installation/#macos) and
[Linux](https://goteleport.com/docs/installation/#linux) can be found at Teleport's website.

### Accessing The Rails Console

#### Non-Production

Always use **non-production** (`gstg` or `pre`) consoles to test and experiment, unless production data is strictly necessary.

The `non-prod-rails-console-ro` role gives you access to non-production (`gstg` or `pre`) consoles.
You do NOT require a request or approval for this role.

```bash
$ tsh login --proxy=production.teleport.gitlab.net
$ tsh ssh rails-ro@console-ro-01-sv-gstg
```

The last command takes some time to return a shell.

Tip: The syntax and options for `tsh ssh` are very similar standard `ssh` command (with some additional options).
See this [guide](https://goteleport.com/docs/connect-your-client/tsh/) for more information on using the `tsh` command-line tool.

#### Production

For accessing the Rails consoles in `gprd`, you need to explicity ask for access.

1. Authenticate to the Teleport instance. This command opens Okta in a browser window:

```bash
$ tsh login --proxy=production.teleport.gitlab.net
```

2. Request approval for the rails console role that you need.

Currently only `prod-rails-console-ro` is implemented, and is only required in `gprd`

```bash
$ tsh login --proxy=production.teleport.gitlab.net --request-roles=prod-rails-console-ro --request-reason="GitLab Issue URL or ZenDesk Ticket URL"
```

This command will pause while it waits for the reviewer to approve the request.
It may appear to hang, but it is waiting for someone to approve it.
The command will return as soon as the request is approved, denied, or expires.

If the command is stopped or times out, but the request is approved, you do not need to request another approval.
Simply login and provide the approved request ID (output by the previous command, or find it in the web interface).

3. Connect to the Rails Console.

```bash
$ tsh login --proxy=production.teleport.gitlab.net --request-id=<request-id>
$ tsh ssh rails-ro@console-ro-01-sv-gprd
```

The last command takes some time to return a shell.

The request ID is shown in the output of `tsh login` when making the initial request, and can also be found attached to
your request notification in [#teleport-requests](https://gitlab.enterprise.slack.com/archives/C06Q2JK3YPM).

The access will be temporary (12 hours) and can be approved by any SRE or Reliability Manager.
Access can be extended before or after expiration using the same process.

## Access Approval

Approvers will get your request via an automated notification in the
[#teleport-requests](https://gitlab.enterprise.slack.com/archives/C06Q2JK3YPM) Slack channel.
If you have additional context, or need to expedite an approval, please comment as a thread under that message.
If the request is urgent, you can ping `@sre-oncall`, but to spread out the workload,
please try to allow some time for others to review first if possible.
If the approval request **does not show up** in [#teleport-requests](https://gitlab.enterprise.slack.com/archives/C06Q2JK3YPM),
feel free to ask someone in that channel to take a look at your request, and provide the request ID.

Approvers will review the issue URL in the request.
If Rails Console access seems like a reasonable step to address that issue, they will approve it.

## Support

If you have any issues using Teleport, or the approval process,
please ask the [Foundations team](https://gitlab.enterprise.slack.com/archives/C0313V3L5T6)
or in the [#infrastructure-lounge](https://gitlab.enterprise.slack.com/archives/CB3LSMEJV) Slack channel.

Note: If you need more time, you can renew your role access before or after expiration using the same method as the initial request.

## Troubleshooting

### Debug

If you have issues connecting, try using the `--debug` flag to display more verbose information.
