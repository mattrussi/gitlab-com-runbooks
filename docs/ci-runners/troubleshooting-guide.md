# CI Runner Troubleshooting Guide

## Table of Contents

[TOC]

## Common Runner Issues and Resolutions


### Runners Manager is Down

There are a wide range of possibilities, although uncommon, for when the runners manager is failing to process jobs.

The reason could be anywhere between the GitLab instance and the runner-manager VM itself.

#### Possible checks

1. Try to login to the problematic node and run `sudo gitlab-runner status`. If the `gitlab-runner` process is not running (output is `gitlab-runner: Service is not running!`), then check that `chef-client` is enabled before attempting to start the process again.
1. Is the issue occurring in only one VM in a given shard? This could indicate the issue is local to that specific runner-manager.
1. Is the issue widespread in all the VMs in a particular shard? This could indicate a faulty configuration, either in Terraform or Chef.
1. Is the issue widespread in all .com hosted shards? This indicates an issue with the GitLab instance, or some other intermediate component; for example, the HAProxy nodes. 

#### Resolution

Depending on the cause, the resolution can range anywhere between restarting the `gitlab-runner` process, to reverting a recent change.

### CI runner manager report a high number of errors

#### Possible checks

1. Check the CI Runenrs Incident Support dashboards [in Grafana](https://dashboards.gitlab.net/dashboards/f/ci-runners/ci-runners).
2. Check the Failures by instance and reason in [this dashboard](https://dashboards.gitlab.net/goto/D8gWNgAHg?orgId=1).
3. Check [.com runner logs](https://log.gprd.gitlab.net/app/r/s/f7x01) for unexpected increase in a particular error.
4. Examine a failed job in detail.
5. SSH into one of the runner-manager VMs experiencing the errors, for example:

    ```bash
    ssh runners-manager-private-blue-1.c.gitlab-ci-155816.internal
    ```

3. Check the status of machines:

    ```bash
    $ sudo gitlab-runner status
    $ sudo su
    # /root/machines_operations.sh list
    # /root/machines_operations.sh count
    ```

4. You can also do a check using Docker Machine:
    > **Notice:**
    > `docker-machine ls` is doing an API call for each machine configured on the host. This might increase the
    > GCP quota Limits usage. Please use this command carefully and consider to skip this step if
    > we're approaching any of the quota limits for an affected project.

    ```bash
    $ sudo su
    # docker-machine ls
    ```

    Save this output for later troubleshooting.
5. Check the process logs as described in [docs general troubleshooting tips](https://docs.gitlab.com/runner/faq/#general-troubleshooting-tips).



## Shared Runners Cost Factors
>
> Available for GitLab.com Admins only

Cost Factor is a multiplier for every CI minute being counted towards the Usage Quota.

`Public` Cost Factor is applied to `public` projects jobs, `Private` Cost Factor is applied to `private` and `internal` projects jobs.

For example, if `Public` Cost Factor of the Runner is set to `0.0`, it would NOT count the time spent executing jobs for `public` projects towards the Usage Quota at all.

Similarly, if `Private` Cost Factor of the Runner is set to `1.0`, it would count every minute spent executing jobs for `private`/`internal` projects without applying any additional multiplier to the time spent.

Setting a value, different from `0.0` and `1.0`, could be used to adjust the "price" of a particular runner.
For instance, setting the multiplier to `2.0` will make each physical minute to consume 2 minutes from the quota.
Setting the multiplier to `0.5` will make each physical minute to consume only 30 seconds from the quota.

It is possible to adjust Cost Factors for the particular runner:

1. Navigate to **Admin > Runners**
2. Find the Runner you wish to update
3. Click edit on the Runner
4. Edit Cost Factor fields and save the changes

Cost Factors are stored in the `ci_runners` DB table, in `public_projects_minutes_cost_factor` and `private_projects_minutes_cost_factor` fields.

Default Cost Factors values are `public_projects_minutes_cost_factor=0.0` and `private_projects_minutes_cost_factor=1.0`.

### Abuse of resources: Cryptocurrency mining

The most common known pattern of abuse is cryptocurrency mining.

Because we limit wallclock minutes, not CPU minutes, miners are motivated to spawn numerous concurrent jobs, to make the most of their wallclock minutes.

Miners often create numerous accounts on GitLab.com, each having its own namespace, project, and CI pipeline. Typically these projects have nearly identical `.gitlab-ci.yml` files, with only superficial differences. Often these files will maximize parallelism, by defining many jobs that can run concurrently and possibly also specifying that each of those jobs should individually be run in parallel.

### Surge of Scheduled Pipelines

When creating a scheduled pipeline in the GitLab UI there are some handy defaults. Unfortunately, they result in a lot of users scheduling pipelines to trigger at the same time on the same day, week, or month.

The biggest spike is caused at 04:00 UTC. This spike is increased on Sundays (for jobs scheduled to be weekly) and on the first of the month (for jobs scheduled monthly). If the first of the month is also a Sunday this is additive and the spike will be even larger.

In the case of a scheduled pipeline surge triggering the alert, it should resolve within ~15 minutes. If it doesn't it likely indicates there's more than just the one cause of the alert (e.g. there is a scheduled pipeline surge **and** abusive behavior in the system)

### GitLab.com usage has outgrown it's surge capacity

Each runner manager tries to maintain a [pool of idle virtual machines](https://ops.gitlab.net/gitlab-cookbooks/chef-repo/-/blob/master/roles/gitlab-runner-srm-gce.json#L19)
to assign to new jobs. This allows jobs to start as soon as they're assigned without waiting for the VM spin-up time. However, if the idle pool is exhausted and new jobs keep coming in, the new jobs will have to wait for availble VMs.

This scenario actually describes the above two scenarios as well, however because the idle count is a hard coded value per runner manager, over time it will need to be updated as usage on GitLab.com grows.

#### How to identify active accounts (namespaces) with large number of pending CI jobs?

To find accounts (a.k.a. namespaces) with large number of pending CI jobs, use the following DB query which finds top 10 namespaces with most number of CI jobs in the `Pending` state.

```psql
##
## Find one of the CI hosts
## If needed use the [host-stats dashboard](https://dashboards.gitlab.net/d/bd2Kl9Imk/host-stats?orgId=1)
##
$ ssh patroni-ci-v14-03-db-gprd.c.gitlab-production.internal
$ sudo gitlab-psql
gitlabhq_production=# SELECT namespace_id, count(id) FROM ci_pending_builds GROUP BY namespace_id ORDER BY count(id) DESC LIMIT 10;
## Example output
 namespace_id | count
--------------+-------
     13264837 | 43325
     33264816 | 32295
     28868183 | 20800
     53264790 | 14618
     33264804 | 14016
     23264777 | 12374
     13264797 |  9838
     32510040 |  8730
     53264820 |  8406
     66778311 |  5470
(10 rows)
```

These namespace ids are all that the abuse-team needs to block the accounts and cancel the running or pending jobs, so if the situation is dire, skip ahead to the "Mitigation" step.

Caveats:

* Normally the namespace called "namespace" can be ignored. It is an "everything else" bucket for the many small namespaces that did not rank in the top-N that get individually tallied. Usually you can ignore it, but if it has an outrageously high count of jobs, that might indicate there are numerous namespaces being collectively aggressive in scheduling jobs (which would warrant further research).
* Namespace 9970 is the `gitlab-org` namespace and is expected to routinely have heavy CI activity.

#### Investigation

To translate these namespace ids into namespace names and URLs, you can (a) run `/chatops run namespace find <id>`, (b) query the Rails console, or (c) query the Postgres database directly.

##### Option A: ChatOps command

The easiest way is to use this ChatOps command in Slack to lookup the namespace name:

```
/chatops run namespace find <namespace_id>
```

##### Option B: Database query

Connect to any Postgres database (primary or replica) and get a `psql` prompt:

```shell
ssh <username>-db@gprd-console
```

or

```shell
ssh patroni-01-db-gprd.c.gitlab-production.internal   # Any patroni is fine, replica or primary.
sudo gitlab-psql
```

Put your namespace ids into the IN-list of the following query:

```sql
select
  id,
  created_at,
  updated_at,
  'https://gitlab.com/' || path as namespace_url
from
  namespaces
where
  id in ( 6334677, 6336008, ... )
order by
  created_at
;
```

##### Option C: Rails console query

Connect to the Rails console server:

```shell
ssh <username>-rails@gprd-console
```

For a single namespace id:

```ruby
[ gprd ] production> Namespace.find_by_id(6334677)
```

For more than a single id, put your namespace ids into the array at the start of this iterator expression:

```ruby
%w[6334677 6336008].each { |id| n = Namespace.find(id); puts "#{id} (#{n.name}): https://gitlab.com/#{n.full_path}" }
```

##### Review the namespaces via the GitLab web UI

To view the namespace (and its projects), you will probably need to authenticate to GitLab.com using your admin account (e.g. `msmiley+admin@gitlab.com`) rather than your normal account, since abusive projects tend to be marked as private.

Often (but not always), both the namespace and the project are disposable, having minimal setup and content, apart from the `.gitlab-ci.yml` file that defines the pipeline jobs. For reference, here is an [example namespace](https://gitlab.com/zabuzhkofaina), its one [project](https://gitlab.com/zabuzhkofaina/zabuzhkofaina), and its [`.gitlab-ci.yml` file](https://gitlab.com/zabuzhkofaina/zabuzhkofaina/blob/master/.gitlab-ci.yml).

In your browser, view the namespace and its project(s). Determine if the namespace or project looks suspicious. Does the namespace and project have minimal setup? Were they freshly created very recently and lack activity apart from initial setup? Is the project empty apart from the `.gitlab-ci.yml` file that defines the pipeline jobs?

View the `.gitlab-ci.yml` file. Does its job definition look like a miner? Does it download an executable, possibly a separate configuration file, and then run numerous long-running jobs?

#### Mitigation

Contact the Abuse Team via Slack (`@abuse-team`), and ask them to run `Scrubber` for the namespace ids you identified above as abusive.

Quick reference:

* [Scrubber runbook](https://gitlab.com/gitlab-com/gl-security/abuse-team/abuse/wikis/Runbook/Mitigation-Tool-%28Scrubber%29)

## Shared CI Runner Timeouts

The shared runner managers have timeouts that can restrict the time a CI job is allowed to run. In a runner config, there is a *Maximum job timeout* field that is described by the following: ```This timeout will take precedence when lower than project-defined timeout and accepts a human readable time input language like "1 hour". Values without specification represent seconds.```

Manually changing this can be done per shared runner manager in the GitLab admin interface under ```Admin Area -> Overview -> Runners```. Select, or search for the runner managers you want to increase (or decrease) the runtime timeout for.

API bulk update idea:

``` bash
for runner in 157328 157329 380989 380990; do
  curl -sL \
       -H "Private-Token: $GITLAB_COM_ADMIN_PAT" \
       -X PUT  "https://gitlab.com/api/v4/runners/$runner" \
       -F 'maximum_timeout=5400' | jq '"\(.description): \(.maximum_timeout)"'
  sleep 1
done
```

Example Issue: <https://gitlab.com/gitlab-com/gl-infra/reliability/-/issues/6547>

## How to detect CI Abuse

* Check [started jobs by project](https://log.gprd.gitlab.net/goto/63f83c2a163fb0b29edc33b19773db25).

### Summary

**Note**: There is additional coverage by trust-and-safety to handle CI abuse up until April 15th, 2021: gitlab-com/gl-security/security-operations/trust-and-safety/operations#509 (see [spreadsheet](https://docs.google.com/spreadsheets/d/1KRGdGFYTPIjN8PAdB3ya283Xj2ydFjJr6U70/edit#gid=673454602) for coverage)

**For all issues be sure to also notify `@trust-and-safety` on Slack**

Be sure to join the `#ci-abuse-alerting` private Slack channel for abuse reports

For information about how to handle certain types of CI abuse, see the [SIRT runbook](https://gitlab.com/gitlab-com/gl-security/runbooks/-/blob/master/sirt/gitlab/cryptomining_and_ci_abuse.md). (gitlab internal)

* For blocking users see the Scrubber Runbook: <https://gitlab.com/gitlab-com/gl-security/runbooks/-/blob/ad11eaf0771badcc9a7ae24885e5f969b420b37a/trust_and_safety/Abuse_Mitigation_Bouncer_Web.md>
* For all issues be sure to also notify `@trust-and-safety` on Slack
* Additional methods of finding potential abusers [issues/12776](https://gitlab.com/gitlab-com/gl-infra/reliability/-/issues/12776#note_530435580)):

### Helpful monitoring links

* [Kibana visualization of started jobs](https://log.gprd.gitlab.net/goto/baca81ec588b366ca0ec68ff6d5e5322)
* [CI pending builds](https://thanos.gitlab.net/graph?g0.range_input=1h&g0.max_source_resolution=0s&g0.expr=sum(ci_pending_builds%7Bfqdn%3D~%22postgres-dr-archive-01-db-gprd%5C%5C.c%5C%5C.gitlab-production%5C%5C.internal%22%2C%20shared_runners%3D%22yes%22%2Chas_minutes%3D~%22yes%22%7D)%20by%20(namespace)%20%3E%20200&g0.tab=0)
* [GCP "Security Command Center"](https://console.cloud.google.com/security/command-center/findings?view_type=vt_severity_type&organizationId=769164969568&orgonly=true&supportedpurview=organizationId&vt_severity_type=All&columns=category,resourceName,eventTime,createTime,parent,securityMarks.marks)
