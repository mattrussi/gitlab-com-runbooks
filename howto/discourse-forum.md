# Management for forum.gitlab.com

The GitLab Community forum is hosted under https://forum.gitlab.com and is
powered by [Discourse](https://www.discourse.org).

All commands are to be run with root privileges.

## Deployment

***The node is a one-off.**

Discourse is deployed using Docker exclusively and for that they have the
[discourse_docker](https://github.com/discourse/discourse_docker) project
where they provide a Docker wrapper for deploying Discourse.

In the case of the GitLab forum, this repo is cloned under `/var/discourse/`.

The directory structure is documented in the
[README](https://github.com/discourse/discourse_docker/blob/master/README.md#directory-structure).

## Updating to newer versions

Generally, Discourse has an [admin web interface](https://forum.gitlab.com/admin/upgrade)
where you can upgrade to newer versions via the UI.

Sometimes this is not possible and the upgrade must be
[operated manually](https://meta.discourse.org/t/how-do-i-manually-update-discourse-and-docker-image-to-latest/23325).
In short, you go to the directory where the deployment repository is cloned,
you pull in the latest changes and rebuild the Docker image:

```sh
cd /var/discourse
git pull origin master
./launcher rebuild app
```

The `app` is the name of the container currently under `/var/discourse/containers/app.yml`.

---

The Discourse team suggests:

- Update Discourse twice a month via web updater
- Update the container every two months
- Update the OS every six months

## Plugins

External plugins are normal Git repos and are defined in `/var/discourse/containers/app.yml`
under `hooks`.

### Plugins we use

We are using the following plugins:

- [discourse-omniauth-gitlab](https://gitlab.com/gitlab-org/discourse-omniauth-gitlab):
  Discourse plugin for the omniauth-gitlab strategy with which you can sign in
  to forum.gitlab.com using your GitLab.com account. Once enabled, it's used
  automatically.
- [discourse-backup-uploads-to-s3](https://github.com/discourse/discourse-backup-uploads-to-s3):
  Upload backups to S3. Once enabled, this setting can be enabled/disabled via the admin
  area.

### Adding or removing a plugin

1. Edit `/var/discourse/containers/app.yml`
1. Add/remove the plugin(s) Git URL(s) under `hooks`:

    ```yml
    hooks:
      after_code:
        - exec:
            cd: $home/plugins
            cmd:
              - mkdir -p plugins
              - git clone https://github.com/discourse/discourse-backup-uploads-to-s3.git
              - git clone https://gitlab.com/gitlab-org/discourse-omniauth-gitlab.git
    ```

1. Rebuild the app:

    ```sh
    cd /var/discourse
    ./launcher rebuild app
    ```

Bear in mind that if a plugin has updated, to pull any changes, the app must be rebuilt.

## Backup

The backup happens automatically once a day, and we keep the
[latest seven](https://forum.gitlab.com/admin/backups).

## Running low on disk space

Running low on disk space might affect backups among others. To clean up some space:

```sh
./launcher cleanup
apt-get autoclean
apt-get autoremove
```

The `cleanup` command removes all containers that have stopped for > 24 hours.
