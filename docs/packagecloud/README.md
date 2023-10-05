<!-- MARKER: do not edit this section directly. Edit services/service-catalog.yml then run scripts/generate-docs -->

**Table of Contents**

[[_TOC_]]

# Packagecloud Service

* [Service Overview](https://dashboards.gitlab.net/d/packagecloud-main/packagecloud-overview)
* **Alerts**: <https://alerts.gitlab.net/#/alerts?filter=%7Btype%3D%22packagecloud%22%2C%20tier%3D%22inf%22%7D>
* **Label**: gitlab-com/gl-infra/production~"Service::PackageCloud"

## Logging

* [ops](https://nonprod-log.gitlab.net/app/r/s/xBFHH)
* [pre](https://nonprod-log.gitlab.net/app/r/s/5ATui)

## Troubleshooting Pointers

* [Packagecloud Infrastructure and Backups](infrastructure.md)
* [Re-indexing a package](reindex-package.md)
* [GPG Keys for Package Signing](../packaging/manage-package-signing-keys.md)
<!-- END_MARKER -->

## Support Requests

We are entitled to product support from Packagecloud.  To open a new support request email: <support@packagecloud.io>

To escalate a support request reach out to the [Reliability General Team](https://about.gitlab.com/handbook/engineering/infrastructure/team/reliability/general.html).

## Updating the License Key

1. Get the new license (most likely this will come from [Packagecloud support](#support-requests)).
1. Update the license in vault (same license key for both environments):

    * [staging](https://vault.gitlab.net/ui/vault/secrets/k8s/kv/pre-gitlab-gke%2Fpackagecloud%2Fpackagecloud/details)
    * [production](https://vault.gitlab.net/ui/vault/secrets/k8s/kv/ops-gitlab-gke%2Fpackagecloud%2Fpackagecloud/details)

1. Trigger a rolling restart:

    ```sh
    kubectl -n packagecloud rollout restart deployment/packagecloud-toolbox
    kubectl -n packagecloud rollout restart deployment/packagecloud-resque
    kubectl -n packagecloud rollout restart deployment/packagecloud-rainbows
    kubectl -n packagecloud rollout restart deployment/packagecloud-web
    ```

## Credentials

### Package key

The package key is used for the pre-release repo which is used for
all GitLab deployments that pull packages from the `gitlab/pre-release` repository.

We do **not** let the wider community pull from this repo because GitLab.com
production and non-production environments use it for testing security updates
and unreleased builds before they are released.

#### Key rotation

Follow this process to rotate the `pre-release` token for an environment:

1. Visit <https://packages.gitlab.com/gitlab/pre-release/tokens>
1. Under _Custom Master Tokens_, click `Revoke` on the token that corresponds to the environment you want to rotate the token for. **This will render the token unusable by deleting the token!**

1. Click `Create Master Token` and enter the environment name in the _Master Token Name_ field
1. Copy the new token value
1. Visit <https://vault.gitlab.net/ui/>
1. Go to the following secrets path for the environment in question: `env/<env>/shared/gitlab-omnibus-secrets`
1. Click on _Create new version_
1. Click on the _JSON_ toggle
1. Look for the path `omnibus-gitlab.package.key` and update the value with the new token.

**NOTE**: when the key gets rotated, the source file does **not** get updated before the first apt upgrade.
This will cause chef runs to fail unless it is manually deleted ([issue](https://gitlab.com/gitlab-com/gl-infra/reliability/-/issues/7459)).

The following knife command can workaround the issue:

```sh
knife ssh -C10 "recipes:omnibus-gitlab\\:\\:default" "sudo rm -f /etc/apt/sources.list.d/gitlab_pre-release.list"
```

Running `chef-client` once the file has been deleted should yield a successful run.
