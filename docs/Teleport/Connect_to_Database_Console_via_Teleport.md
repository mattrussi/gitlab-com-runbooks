# How to connect to a Database console using Teleport

## Background info about [Teleport](https://goteleport.com/teleport/docs/)

Database consoles in Staging/Production are accessed via Gravitational [Teleport](https://goteleport.com/teleport/docs/). Our legacy Database consoles (using the console servers) are in the process of being removed for most use cases.

- The main reasons for this change are security and compliance: With Teleport we'll have fully flexible, on-demand, and audited access to our Database consoles and to some other terminal/CLI tools, like `kubectl`, [Rails Console](Connect_to_Rails_Console_via_Teleport.md), and more.
- Teleport's goal is to provide a Unified Access Plane for all of our infrastructure. [Here](https://goteleport.com/teleport/docs/#why-use-teleport) you can find some of the most popular use cases for Teleport.
- We evaluated Teleport thoroughly (see this [issue](https://gitlab.com/gitlab-com/gl-infra/reliability/-/issues/11568)) and found it to comply with most of our infrastructure access requirements, unlike some of its competitors ([Okta-ASA](https://gitlab.com/gitlab-com/gl-infra/reliability/-/issues/12042), [Hashicorp Boundary](https://gitlab.com/gitlab-com/gl-infra/reliability/-/issues/11666) and others).

## Access Requests

Before you start using Teleport, you must be assigned the app in Okta.  This should be a part of your role's baseline group assignment. In most cases there should be no additional action required to gain access to the services appropriate to your role. If your onboarding is complete and you still do not have access to the Teleport app in Okta, open an [access request](https://about.gitlab.com/handbook/business-technology/team-member-enablement/onboarding-access-requests/access-requests/) and follow the appropriate approval methods.

## How to use Teleport to connect to Database console

There are two ways to use to Teleport to connect to a Database console:

1. Installing [tsh](https://goteleport.com/teleport/docs/cli-docs/#tsh), the Teleport CLI client. This is the recommended way.
1. Via the Teleport HTTP portal ([https://teleport.gstg.gitlab.net:3080](https://teleport.gstg.gitlab.net:3080) in staging).

### Installing tsh

On MacOS, It is as simple as running, from your laptop's console:

```shell
brew install teleport
```

However, the database console requires `psql` so if it is not already installed on your machine, you'll also have to run:

```shell
brew install postgres
```

Linux install instructions are [also available on the Teleport site](https://goteleport.com/docs/installation/#linux)

### Accessing the Database console via Teleport

> Note: It is not required, but it is easier to be logged in to Okta already before starting

1. Authenticate to the Teleport server
2. Unless using read only access in staging, request approval for the database role that you need
3. Log in to the database with the appropriate database user
4. Connect the database console

The access will be temporary (`12h` max) and can be approved by any SRE or Reliability Manager.  The `@sre-oncall` can help if it's urgent, but if you can wait it is considerate to spread the load out by asking the wider SRE team in `#infrastructure-lounge`. Access can be extended before or after expiration using the same process.

> Tip: As long as you understand that two separate things are happening in the second command below, you can skip the first and just use the second.

Authenticate to the Teleport proxy/server. This command opens Okta in a browser window:

```shell
tsh login --proxy=teleport.gstg.gitlab.net
```

> Note: The `database-ro` role in the `gstg` environment does not require a request or approval, so you can skip the next step. Use the `database-ro` role unless you know for sure that you need something else. For Package Team members, they additionaly have `registry-database-ro` role in the `gstg`, which gives them access to registry database without approval.

If you need to request a role which includes elevated permissions for the Database console. Request any of the following roles in either `gstg` or `gprd`:

#### For `main` and `CI` databases

- `database`
- `database-ro`

#### For `registry` database

- `registry-database`
- `registry-database-ro`

#### For all databases to request superuser priveleges (DBREs only)

- `database-admin`

using the following format.

```shell
tsh login --proxy=teleport.gstg.gitlab.net --request-roles=database --request-reason="Issue-URL or explanation"
```

This command will pause while it waits for the approver to approve the request.  It may appear to hang, but it is waiting for someone to approve it.  The command will return as soon as the request is approved, denied, or times out.

> Note: All examples are for the **staging environment** only! This is to limit the consequences of unintended copy/paste errors.  To connect to the production environment, change `gstg` to `gprd`

If the command is stopped or times out, but the request is approved, you don't need to request another approval.  Simply login and provide the approved request ID (output by the previous command, or find it in the web interface):

```shell
tsh login --request-id=<request-id>
```

The request ID is shown in the output of `tsh login` when making the initial request, and can also be found attached to your request notification in `#infrastructure-lounge`.

> Note: These examples assume you are requesting read-only access.  For read-write, simply `--request-roles=database` rather than `--request-roles=database-ro`.  Please default to read-only though, since we will have stricter requirements for approving read-write access.

#### Access approval

Approvers will get your request via an automated notification in the `#infrastructure-lounge` Slack channel.  If you have additional context,
or need to expedite an approval, please comment as a thread under that message.  If the request is urgent, you can ping `@sre-oncall`, but
to spread out the workload please try to allow some time for others to review first if possible. If the approval request **doesn't show up** in
`#infrastructure-lounge` feel free to ask someone in that channel to take a look at your request, and provide the request ID.

Approvers will review the issue URL in the request and if database access seems like a reasonable step to address that issue, they will approve it.

#### Database Login

Once an approval is issued, the next step is to log in to the database. Note that the `--db-name` option refers to the internal database schema name.  The database name at the end of the line refers to the database host that Teleport is pointing to (which you can see with `tsh db ls`):

For the Main Database:

```shell
tsh db login --db-user=console-ro --db-name=gitlabhq_production db-secondary
```

For the CI Database:

```shell
tsh db login --db-user=console-ro --db-name=gitlabhq_production db-secondary-ci
```

For the Registry Database:

```shell
tsh db login --db-user=console-ro --db-name=gitlabhq_registry db-secondary-registry
```

Remember that your access request, its approval, and any associated database logins will expire in `12h` maximum unless renewed.

> Tip: The above command connects to a secondary database (`db-secondary`).  Secondaries are always read only.  If you need write access, you will have to log in to `db-primary` in addition to connecting as a database user with write permissions. The `console-rw` user is allowed to write and permission is granted as part of the `database` role. Once logged in to teleport, you can view the databases available to your role with `tsh db ls`

The database login command only needs to be executed once per day, unless you manually log out or need to change something.  Once logged in, you can connect and disconnect from the console as many times as needed.

For the Main Database:

```shell
tsh db connect db-secondary
```

For the CI Database:

```shell
tsh db connect db-secondary-ci
```

For the Registry Database:

```shell
tsh db connect db-secondary-registry
```

> Tip: use the `tsh status` command to show which logins you are currently approved for.

## Support

If you have any issues using Teleport, or this approval process, please ask the **Reliability team** (SREs and/or managers) in the [#production](https://gitlab.slack.com/archives/C101F3796) or [#infrastructure-lounge](https://gitlab.slack.com/archives/CB3LSMEJV) Slack channels.

> Note: If you need more time, you can renew your role access approval before or after expiration using the same method as the initial request

## More detail

The Teleport login process is a little different from other services.  With Teleport, you are not opening a network session with a server so much as requesting that the server sign your certificate and add the appropriate role permissions to it.

The `tsh login` command requests that the server validate your identity with Okta and give you a certificate which can be used as the equivalent of an SSH key.  However, in contrast to an SSH key, this certificate expires, and also contains information on which roles you are approved for.  This information is displayed at login, but can be viewed again with `tsh status`.

```text
$ tsh status
> Profile URL:        https://teleport.gstg.gitlab.net:3080
  Logged in as:       yourname@gitlab.com
  Cluster:            gstg-teleport-cluster
  Roles:              database-requestor, database-ro-requestor
  Logins:             yourname@gitlab.com
  Kubernetes:         disabled
  Valid until:        2021-04-13 21:38:09 -1000 HST [valid for 11h27m0s]
  Extensions:         permit-pty
```

Note that the default certificate does not have the `database-ro` role assigned. The default certificate allows you to interact with the Teleport server, and to request more roles, but does not allow connecting to any other services.

To request permission to connect to a service, you must use the `--request-roles` flag.  You can request a role after already having a valid certificate, or simply by adding the flag to your initial login. Each `--request-roles` requires a `--request-reason`. It's best to use the URL of the issue or incident that this activity relates to.

```shell
tsh login --proxy=teleport.gstg.gitlab.net --request-roles=database-ro --request-reason="Issue-URL or explanation"
```

Once approved, the server will replace your loally stored certificate with an updated one, and your newly valid roles will appear in the `tsh status` output.
