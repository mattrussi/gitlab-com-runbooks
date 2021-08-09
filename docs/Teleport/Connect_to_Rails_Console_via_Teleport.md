# How to connect to a Rails Console using Teleport

### Background info about [Teleport](https://goteleport.com/teleport/docs/):
We have a new way to access our Rails consoles in Staging/Production - via Gravitational [Teleport](https://goteleport.com/teleport/docs/). Our standard Rails console is in the process of being fully removed.

- The main reason for this change is security and compliance: With Teleport we'll have fully flexible, on-demand, and audited access to our Rails consoles and to some other terminal/CLI tools, like Kubernetes-ctl, Database access via psql and more.
- Teleport's goal is to provide a Unified Access Plane for all our infrastructure. [Here](https://goteleport.com/teleport/docs/#why-use-teleport) you can find some of the most popular use cases for Teleport.
- We evaluated Teleport thoroughly (see this [issue](https://gitlab.com/gitlab-com/gl-infra/infrastructure/-/issues/11568)) and found it to comply with most of our infrastructure access requirements, unlike some of its competitors ([Okta-ASA](https://gitlab.com/gitlab-com/gl-infra/infrastructure/-/issues/12042), [Hashicorp Boundary](https://gitlab.com/gitlab-com/gl-infra/infrastructure/-/issues/11666) and others).

## How to use Teleport to connect to Rails console
There are two ways to use to Teleport to connect to a Rails console:
1. Installing [**tsh**](https://goteleport.com/teleport/docs/cli-docs/#tsh), the Teleport CLI client. This is the recommended way.
1. Via the Teleport HTTP portal (https://teleport.gstg.gitlab.net:3080 in staging).

#### Installing tsh
On MacOS, It is as simple as running, from your laptop's console:

`$> brew install teleport`

Linux install instructions are [also available on the Teleport site](https://goteleport.com/docs/installation/#linux)

#### Accessing the Rails console via Teleport

> Note: It is not required, but it is easier to be logged in to Okta already before this step

The access will be temporary (`24h` max) and approved by any SRE or Reliability Manager.  The `@sre-oncall` can help if it's urgent, but it's considerate to spread the load out by asking the wider SRE team in `#infrastructure-lounge` if you can wait. Access can be extended past 24 hours, with approval, using the same process.

> Tip: As long as you understand that two separate things are happening in the second command below, you can skip the first and just use the second.

Login to the Teleport proxy/server:

`$> tsh login --proxy=teleport.gstg.gitlab.net`

And finally you request a role to connect to the staging Rails console - for production, see the note below:

`$> tsh login --proxy=teleport.gstg.gitlab.net --request-roles=rails-ro --request-reason="Issue-URL or explanation"`

This command will pause while it waits for the approver to approve your request.  It may appear to hang, but it will return as soon as the request is approved or denied.

> Note: These examples are for the **staging environment** only! This is to prevent unintended copy/paste behavior.  To connect to the production environment, change `gstg` to `gprd`

#### Access approval

Approvers will get your request via an automated notification in Slack. This posts a notification into the `#infrastructure-lounge` channel.  If you have additional context, or need to expedite an approval, please comment as a thread under that message.  If the request is urgent, you can ping `@sre-oncall`, but to spread out the workload please try to allow some time for others to review first if possible.

Approvers will review the issue URL in the request and if console access seems like a reasonable step to address that issue, they will approve it.

Once an approval is issued, access the Rails console via:

`$> tsh ssh rails-ro@console-ro-01-sv-gstg`

Remember that your access request - and its approval - will expire in `24h` maximum.

> Tip: The syntax and options for `tsh ssh` are very similar to `ssh` (with some additional options), so it's possible to do something like `alias ssh="tsh ssh"`

If you have any issues using Teleport, or this approval process, please ask the **Reliability team** (SREs and/or managers) in the [#production](https://gitlab.slack.com/archives/C101F3796) or [#infrastructure-lounge](https://gitlab.slack.com/archives/CB3LSMEJV) channels.

> Note: If you need more time, you can renew your role access approval at any time using the same method as the initial request

### More detail

The login process is a little different from other services.  With Teleport, you are not logging in so much as requesting that the server sign your key and add the permissions that you have to it.

`tsh login` requests that the server validate your identity with Okta and give you a key which can be used as the equivalent of an SSH key.  However, in contrast to an SSH key, this key expires, and also contains which roles you are allowed to log in as.  You can view this information with `tsh status` after successful login.

```shell
$ tsh status
> Profile URL:        https://teleport.gstg.gitlab.net:3080
  Logged in as:       yourname@gitlab.com
  Cluster:            gstg-teleport-cluster
  Roles:              backend-developer
  Logins:             yourname@gitlab.com
  Kubernetes:         disabled
  Valid until:        2021-04-13 21:38:09 -1000 HST [valid for 11h27m0s]
  Extensions:         permit-pty
```

Note that the default token does not have the `rails-ro` role and does not have the `rails-ro` login available. This key allows you to interact with the server, and to reuqest more roles, but does not allow connecting to any other services.

To request permission to connect to a service, you must use the `--request-roles` flag.  You can request a role after already having a valid session key, or more simply, by just adding the flag to your initial login:

````shell
tsh login --proxy=teleport.gstg.gitlab.net --request-roles=rails-ro --request-reason="Issue-URL or explanation"
````

Each request requires a reason, and it's best to include the URL of the issue or incident that this relates to.

