# Teleport Approver Workflow

To use the approval workflows, you must be running the enterprise version of the `tctl` client.  This can be installed locally on a laptop, or can be run on the teleport servers.  Note that the version installed with `brew install teleport` is NOT the enterprise version.  It will work fine for client connections, but will not work for approvals.

To install the enterprise version on a MacOS workstation, download and install this package: https://get.gravitational.com/teleport-ent-6.1.1.pkg 

> You must be logged in with the role `teleport-approver` to use these commands. That means you'll need to be in the `GitLab - SRE Managers` group in Okta. (This is configured in the [okta-connector.yaml](https://gitlab.com/gitlab-cookbooks/gitlab-teleport/-/blob/master/templates/default/okta-connector.yaml.erb#L14) file)

```shell
$ tctl request ls
Token                                Requestor         Metadata       Created At (UTC)    Status   Request Reason Resolve Reason
------------------------------------ ----------------- -------------- ------------------- -------- -------------- --------------
8f1532ba-1f96-46c3-8695-b209d3e70507 dsylva@gitlab.com roles=rails-ro 11 Mar 21 19:07 UTC PENDING 11234
```

```shell
$ tctl request approve 8f1532ba-1f96-46c3-8695-b209d3e70507
```

```shell
$ tctl request ls
Token                                Requestor         Metadata       Created At (UTC)    Status   Request Reason Resolve Reason
------------------------------------ ----------------- -------------- ------------------- -------- -------------- --------------
8f1532ba-1f96-46c3-8695-b209d3e70507 dsylva@gitlab.com roles=rails-ro 11 Mar 21 19:07 UTC APPROVED 11234
```

### Alternatives

Access requests can also be viewed on the web interface, though they can't be approved there: https://teleport.gstg.gitlab.net:3080/web/requests

### Troubleshooting

If you see the following errors:

`ERROR: your credentials have expired, please login using tsh login`

`ERROR: lstat /private/var/lib/teleport: no such file or directory`

It's likely that you need to log in or re-authenticate with:

```shell
tsh login --proxy=teleport.gstg.gitlab.net
```
> This example is for the `gstg` environment.  Replace `gstg` with `gprd` for production

