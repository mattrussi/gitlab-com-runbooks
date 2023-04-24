# PackageCloud Infrastructure and Backups

This document will cover how our packagecloud infrastructure works, how
backups are taken, and how to restore said backups. `packages.gitlab.com`
is hosted in AWS us-west-1 (N. California). There are also
[PackageCloud docs](https://packagecloud.atlassian.net/wiki/display/ENTERPRISE/Backups)
on the entire backup process.

## Support Requests

We are entitled to product support from PackageCloud.  To open a new support request email: support@packagecloud.io

To escalate a support request reach out to the [Reliability General Team](https://about.gitlab.com/handbook/engineering/infrastructure/team/reliability/general.html).

## How Does PackageCloud Work?

PackageCloud is provided as an omnibus package, just like GitLab. This
package includes everything that one would need to begin using PackageCloud.
We install and configure PackageCloud via the [gitlab-packagecloud](https://gitlab.com/gitlab-cookbooks/gitlab-packagecloud) chef cookbook. The
omnibus package contains:

* mysql
* nginx
* rainbows
* redis
* resque
* unicorn

Most notably, PackageCloud uses MySQL, not PostgreSQL like most of our
applications.

**NOTE**: We do not use the redis or mysql local instances. Instead, we depend on configured
RDS cloud database and ElastiCache instances in AWS.

We have configured PackageCloud to send all of the packages to an S3 bucket.
When a package is pushed to the repo, it is automatically uploaded to S3. We use
CloudFront to put package downloads behind a CDN. The configuration of
CloudFront and all associated services was done by PackageCloud itself via
`packagecloud-ctl`. The credentials for CloudFront and the S3 bucket are stored
in the `chef-vault`.

It is important to realize that the PackageCloud application manages the
CloudFront instance. We do not manage it via Terraform like other AWS resources.

## What Is Backed Up?

PackageCloud performs no local backups since we are using an RDS cluster for the database.
Backups are created as part of the RDS configuration. Backups are taken once a day and
removed after 30 days.

The config is not backed up as it is safely in Chef.

There is no need to back up the packages themselves as they are already stored in S3.
It is unlikely that we will ever have the need to restore packages, but the packages
bucket uses Amazon's [cross-region replication](http://docs.aws.amazon.com/AmazonS3/latest/dev/crr.html)
so that we can have extra certainty that the packages will survive.

## Backup Failure Notifications

To Be Documented

## DB Restores for validation

To Be Documented

## Updating the License Key

1. Get the new license. You may need to contact PackageCloud support.
2. Update the license in vault.
3. Run chef to update the configuration with the new license.
4. **RESTART** PackageCloud, a reconfigure may not be enough. You should make sure unicorn and nginx have been restarted.

## Credentials

### Package key

The package key is used for the prerelease repo which is used for
all GitLab deployments that pull packages from

```
repo:    gitlab/pre-release
```

We do not let the wider community pull from this repo because GitLab.com
production and non-production environments use it for testing security updates
and unreleased builds before they are released.

#### Key rotation

* To rotate the package key visit
<https://packages.gitlab.com/gitlab/pre-release/tokens> and select `rotate`

* Update the secret in each environment, for example:

```
    ./bin/gkms-vault-edit gitlab-omnibus-secrets gprd
    ./bin/gkms-vault-edit gitlab-omnibus-secrets gstg
    ./bin/gkms-vault-edit gitlab-omnibus-secrets ops
    ./bin/gkms-vault-edit gitlab-omnibus-secrets dev
    ./bin/gkms-vault-edit gitlab-omnibus-secrets dr
    ./bin/gkms-vault-edit gitlab-omnibus-secrets pre
    ./bin/gkms-vault-edit gitlab-omnibus-secrets testbed

# ... and change the following

  "omnibus-gitlab": {
    "package": {
      "key": "abc123"
    },

```

* _Note: For an updated list of envs see <https://ops.gitlab.net/gitlab-cookbooks/chef-repo/blob/master/bin/gkms-vault-common#L56>_
* Because of <https://gitlab.com/gitlab-com/gl-infra/reliability/-/issues/7459> , after the update chef runs will fail because the sources file is not updated
  automatically, the following knife command can workaround the issue:

```
knife ssh -C10  "recipes:omnibus-gitlab\\:\\:default" "sudo rm -f /etc/apt/sources.list.d/gitlab_pre-release.list"
```

* Verify that chef runs complete successfully after deleting the sources file
