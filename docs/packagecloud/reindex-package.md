# Re-indexing a package

**Table of Contents**

[TOC]

If the indexing of a package in PackageCloud fails, you will need to manually trigger the reindexing of the package in question.

Failed indexing will show stack traces in [Elasticsearch](https://nonprod-log.gitlab.net/app/r/s/Qg7LN) and you will see the `Indexing` yellow label in the UI. Indexing can sometimes take a while so seeing the label in the UI doesn't necessarily mean a package has failed indexing. Best to confirm that there are indexing errors in the [logs](https://nonprod-log.gitlab.net/app/r/s/Qg7LN) before you go through this process.

## Manually trigger a re-index

1. Connect to the `ops-gitlab-gke` k8s cluster and switch context to it

1. Open a shell on the toolbox pod:

    ```sh
    kubectl -n packagecloud exec -it deployments/packagecloud-toolbox -c packagecloud -- bash
    ```

1. Open the rails console:

    ```sh
    packagecloud-ctl console
    ```

1. Once the rails console has loaded, copy in this helper function to help re-indexing:

    ```ruby
    def package_reindex(username, repo, path)
      package_info = path.split('/')
      distro_version = Distribution.find_by_index_name!(package_info[0]).distro_versions.find_by(index_name: package_info[1])
      user = User.find_by(name: username)
      repository = Repository.find_by(name: repo, user_id: user.id)
      repository.find_package_by_dist_filename(
        distro_version_id: distro_version.id,
        package: package_info[2]
      ).reindex
    end
    ```

1. You can now call the function to re-index your packages:

    ```ruby
    package_reindex('<username>', '<repository>', '<file>')
    ```

    - First parameter is the username that the repository belongs to -- e.g., `gitlab`
    - Second parameter is the repository name -- e.g., `gitlab-ce`, `gitlab-ee`, `unstable`, `nightly`
    - Third parameter is the `<distro name>/<distro version>/<file>` to reindex -- e.g., `el/7/gitlab-ce-11.4.12-ce.0.el7.x86_64.rpm`

    For example:

    ```ruby
    package_reindex('gitlab', 'gitlab-ce', 'el/7/gitlab-ce-11.4.12-ce.0.el7.x86_64.rpm')
    ```

    You should see something like the following:

    ```text
    irb(main):035:0> package_reindex('gitlab', 'gitlab-ce', 'el/7/gitlab-ce-11.4.12-ce.0.el7.x86_64.rpm')
    Reindex: 7 30
    Enqueuing Deb::IndexJob for 7 gitlab/gitlab-ce 30 7
    added {"class":"Deb::IndexJob","args":[7,30]} to queue:indexer
    => true
    ```
