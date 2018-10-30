# Pingdom

## How to configure checks in Pingdom

* Pingdom checks are configured in the `pingdom/pingdom.yml` file
* When changes to this file are merged to `master`, the `deploy_pingdom_checks` GitLab CI will execute.
* This job will perform 3 tasks:
  * It will insert any new checks that have been added to the file. These checks will be prefixed with `check:`
  * It will remove any checks in Pingdom with the prefix `check:` that are not in this file
  * It will update any other checks from `pingdom/pingdom.yml`

### `pingdom.yml` Details

The `pingdom.yml` is structured as follows:

```yaml
unique_tag: "pingdom-automated" # This is a tag which only checks in this file should include
defaults:
  timeout_ms: 2000              # The default timeout in milliseconds
  resolution_minutes: 5         # The amount of time before raising an alert
checks:
  # Each check has the following structure
  - url: https://gitlab.com/gitlab-org/gitlab-ce/
    timeout_ms: 5000            # The timeout for this check
    tags:                       # Any additional tags to add to the check
      - gitaly
      - database
    teams:                      # Teams to associate the check with. See Pingdom for a list of teams
      - Infrastructure
```
