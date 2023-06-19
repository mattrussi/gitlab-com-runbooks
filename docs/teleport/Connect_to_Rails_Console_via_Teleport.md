# How to connect to a Rails Console using Teleport

## Background info about [Teleport](https://goteleport.com/teleport/docs/)

Rails consoles in Staging/Production are accessed via Gravitational [Teleport](https://goteleport.com/teleport/docs/). Our legacy Rails consoles (using the console servers) are in the process of being fully removed for most use cases.

- The main reasons for this change are security and compliance: With Teleport we'll have fully flexible, on-demand, and audited access to our Rails consoles and to some other terminal/CLI tools, like `kubectl`, [Database access via psql](Connect_to_Database_Console_via_Teleport.md) and more.
- Teleport's goal is to provide a Unified Access Plane for all our infrastructure. [Here](https://goteleport.com/teleport/docs/#why-use-teleport) you can find some of the most popular use cases for Teleport.
- We evaluated Teleport thoroughly (see this [issue](https://gitlab.com/gitlab-com/gl-infra/reliability/-/issues/11568)) and found it to comply with most of our infrastructure access requirements, unlike some of its competitors ([Okta-ASA](https://gitlab.com/gitlab-com/gl-infra/reliability/-/issues/12042), [Hashicorp Boundary](https://gitlab.com/gitlab-com/gl-infra/reliability/-/issues/11666) and others).

## Access Request

Before you start using Teleport, you must be assigned the app in Okta.  This should be a part of your role's baseline group assignment. In most cases there should be no additional action required to gain access to the services appropriate to your role. If your onboarding is complete and you still do not have access to the Teleport app in Okta, open an [access request](https://about.gitlab.com/handbook/business-technology/team-member-enablement/onboarding-access-requests/access-requests/) and follow the appropriate approval methods.

It is worth noting that the current access granted is a read-only access, if you need to perform write operations to the production environment, then declare a change in `#production` slack channel using the `/change declare` command, after filling the steps and other details, an SRE should be able to execute the change for you.

## How to use Teleport to connect to Rails console

There are two ways to use to Teleport to connect to a Rails console:

1. Installing [tsh](https://goteleport.com/teleport/docs/cli-docs/#tsh), the Teleport CLI client. This is the recommended way.
1. Via the Teleport HTTP portal:

- <https://staging.teleport.gitlab.net/> for staging
- <https://production.teleport.gitlab.net/> for production

### Installing tsh

Official packages for [macOS](https://goteleport.com/docs/installation/#macos) and [Linux](https://goteleport.com/docs/installation/#linux)
can be found at Teleport's website.

#### Accessing the Rails console via Teleport

Always use staging to test and experiment, unless production data is strickly necessary.

##### Staging

The `rails-console-ro-gstg` role in the `gstg` environment does not require a request or approval.

```shell
tsh login --proxy=staging.teleport.gitlab.net
tsh ssh rails-ro@console-ro-01-sv-gstg
```

> Tip: The syntax and options for `tsh ssh` are very similar to `ssh` (with some additional options), so it's possible to do something like `alias ssh="tsh ssh"`

##### Production

1. Authenticate to the Teleport proxy/server. This command opens Okta in a browser window:

```shell
tsh login --proxy=production.teleport.gitlab.net
```

2. Request approval for the rails console role that you need

Currently only `rails-console-ro-gprd` is implemented, and is only required in `gprd`

```shell
tsh login --proxy=production.teleport.gitlab.net --request-roles=rails-console-ro-gprd --request-reason="Issue-URL or explanation"
```

This command will pause while it waits for the approver to approve the request.  It may appear to hang, but it is waiting for someone to approve it.  The command will return as soon as the request is approved, denied, or times out.

If the command is stopped or times out, but the request is approved, you don't need to request another approval.  Simply login and provide the approved request ID (output by the previous command, or find it in the web interface):

3. Connect to the Rails Console

```shell
# Login with the request ID if you have a different session (e.g. made a request using the web)
tsh login --proxy=production.teleport.gitlab.net --request-id=<request-id>
# Connect to Rails Console
tsh ssh rails-ro@console-ro-01-sv-gprd
```

The request ID is shown in the output of `tsh login` when making the initial request, and can also be found attached to your request notification in `#infrastructure-lounge`.

The access will be temporary (`12h` max) and can be approved by any SRE or Reliability Manager.  The `@sre-oncall` can help if it's urgent, but if you can wait it is considerate to spread the load out by asking the wider SRE team in `#infrastructure-lounge`. Access can be extended before or after expiration using the same process.

### Access approval

Approvers will get your request via an automated notification in the `#infrastructure-lounge` Slack channel.  If you have additional context,
or need to expedite an approval, please comment as a thread under that message.  If the request is urgent, you can ping `@sre-oncall`, but
to spread out the workload please try to allow some time for others to review first if possible. If the approval request **doesn't show up** in
`#infrastructure-lounge` feel free to ask someone in that channel to take a look at your request, and provide the request ID.

Approvers will review the issue URL in the request and if Rails Console access seems like a reasonable step to address that issue, they will approve it.

#### Console Login

Once an approval is issued, access the Rails console via:

```shell
tsh ssh rails-ro@console-ro-01-sv-gprd
```

Remember that your access request, its approval, and any associated sessions will expire in `12h` maximum unless renewed.

> Tip: The syntax and options for `tsh ssh` are very similar to `ssh` (with some additional options), so it's possible to do something like `alias ssh="tsh ssh"`

## Support

If you have any issues using Teleport, or this approval process, please ask the **Reliability team** (SREs and/or managers) in the [#production](https://gitlab.slack.com/archives/C101F3796) or [#infrastructure-lounge](https://gitlab.slack.com/archives/CB3LSMEJV) Slack channels.

> Note: If you need more time, you can renew your role access approval before or after expiration using the same method as the initial request

### More detail

The Teleport login process is a little different from other services.  With Teleport, you are not opening a network session with a server so much as requesting that the server sign your certificate and add the appropriate role permissions to it.

The `tsh login` command requests that the server validate your identity with Okta and give you a certificate which can be used as the equivalent of an SSH key.  However, in contrast to an SSH key, this certificate expires, and also contains information on which roles you are approved for. This information is displayed at login, but can be viewed again with `tsh status`.

```shell
$ tsh status
> Profile URL:        https://staging.teleport.gitlab.net:443
  Logged in as:       <username>@gitlab.com
  Cluster:            staging.teleport.gitlab.net
  Roles:              <roles>
  Logins:             <username>, rails, rails-ro, <any other logins (SSH)>
  Kubernetes:         enabled
  Kubernetes groups:  <k8s groups>
  Valid until:        2023-05-02 07:00:26 +1200 NZST [valid for 11h49m0s]
  Extensions:         login-ip, permit-agent-forwarding, permit-port-forwarding, permit-pty, private-key-policy
```

Note that the default certificate might not have any roles assigned, allowing you to interact with the Teleport server, and to request more roles, but does not allow connecting to any other services.

To request permission to connect to a service, you must use the `--request-roles` flag.  You can request a role after already having a valid certificate, or simply by adding the flag to your initial login. Each `--request-roles` requires a `--request-reason`. It's best to use the URL of the issue or incident that this activity relates to.

```shell
tsh login --proxy=staging.teleport.gitlab.net --request-roles=rails-console-ro-gstg --request-reason="Issue-URL or explanation"
```

Once approved, the server will replace your loally stored certificate with an updated one, and your newly valid roles will appear in the `tsh status` output.
