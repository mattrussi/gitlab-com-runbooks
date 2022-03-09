## Re-indexing a package

If the indexing of a package in PackageCloud fails, someone will need to re-index the package.

Failed indexing will show stack traces in the `/var/log/packagecloud/packagecloud-rails/rpm_indexer.log` or `/var/log/packagecloud/packagecloud-rails/deb_indexer.log` (depending on the package type).
And will still have the 'Indexing' yellow label in the UI. (Note that sometimes indexing can take an hour or two if the
node is busy (if its in the middle of a backup for example), so verify that errors are occurring by checking the logs before re-indexing)

### Manually trigger a re-index

Once sshed into the node, switch to the `packagecloud` user, navigate to the packagecloud rails service, and launch the rails console:

```sh
$ sudo su - packagecloud
$ bash
$ cd /opt/packagecloud/embedded/service/packagecloud-rails/
$ /opt/packagecloud/embedded/bin/bundle exec rails console -e onpremise
```

Once the rails console has loaded, copy in this helper function to help re-indexing.

```ruby
def package_reindex(repo, path)
  package_info = path.split('/')
  distro_version = Distribution.find_by_index_name!(package_info[0]).distro_versions.find_by(index_name: package_info[1])
  repository = Repository.find_by(name: repo, user_id: 7)
  repository.find_package_by_dist_filename(distro_version_id:  distro_version.id, package: package_info[2]).reindex
end
```

Then you can call the function to re-index your packages.

```ruby
package_reindex('gitlab-ce', 'el/7/gitlab-ce-11.4.12-ce.0.el7.x86_64.rpm')
```

- The first parameter is the repository (`gitlab-ce`, `gitlab-ee`, `unstable`, `nightly`)
- The second parameter is the index path, indexed by distribution and filename. `(distro)/(distro_version)/(filename)`.
  Which can be copied from the package url in the PackageCloud UI. For a package at
  `https://packages.gitlab.com/gitlab/gitlab-ce/packages/el/7/gitlab-ce-11.4.12-ce.0.el7.x86_64.rpm` we would use
  `el/7/gitlab-ce-11.4.12-ce.0.el7.x86_64.rpm`

## Re-index all packages at a version

We have occasionally seen instances where indexing processes were interupted, and we had to trigger a re-index of
all packages of the specific version. In order to speed this in the future, the follwing can be used to re-index
all public Omnibus GitLab packages at a given version.

```ruby
def package_reindex_version(version)
  return nil if version.nil?

  gitlab_repos = Repository.where(user_id: 7).select {|repo| repo.name.match? /^gitlab-[ce]e$/ }
  gitlab_repos.each do |repo|
    deb_packages = repo.deb_packages.select { |pkg| pkg.filename.include? version }
    deb_packages.each { |pkg| pkg.reindex }

    rpm_packages = repo.rpm_packages.select { |pkg| pkg.filename.include? version }
    rpm_packages.each { |pkg| pkg.reindex }
  end
end
```

Then you can call the function to reindex all public packages at a specific `Major.Minor.Patch` version.

```ruby
package_reindex_version('14.6.6')
```

Functionally:
1. `version` must not be `nil`.
1. Walk all packages of `gitlab-ee` and `gitlab-ce` repositories, for both `deb` and `rpm` types
1. If their filename `include?` supplied `version`, collect them to have `pkg.reindex` called.
