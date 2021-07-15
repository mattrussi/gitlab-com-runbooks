**Table of Contents**

[[_TOC_]]

#  Zlonk Service
* **Alerts**: https://alerts.gitlab.net/#/alerts?filter={type%3D%22zlonk.postgres%22}
* **Label**: None at this time.

## Overview

Zlonk creates and destroys ZFS clones. In its [first iteration](https://gitlab.com/gitlab-com/gl-infra/zlonk/-/blob/master/bin/zlonk.sh), it is a simple shell script that is custom to the generation of Postgres cloned replicas for use by the Data Team. Other uses uses include the generation of ad-hoc replicas for testing purposes.

It currently only runs from `cron` on `patroni-v12-zfs-01-db-grpd`.

#### Projects and instances

Zlonk is called with two arguments: a `project` and an `instance`. A project is simply a way to group instances. For instance, the `infra` project can have three instances, `prod1234`, `gerir`, and `delayed`. Each instance is a completely independent ZFS clone with its associated Postgres instance.

#### Zlonk acts like a switch

The current version of Zlonks acts like a switch: when a clone is not present, it creates it; when it it present, it destroys it.

## Logging

* Zlonk: `/var/log/gitlab/zlonk/<project>/<instance>/zlonk.log`

<!-- ## Summary -->

<!-- ## Architecture -->

<!-- ## Performance -->

<!-- ## Scalability -->

<!-- ## Availability -->

<!-- ## Durability -->

<!-- ## Security/Compliance -->

## Monitoring/Alerting

Zlonk implements [job completion](https://gitlab.com/gitlab-com/runbooks/-/blob/master/docs/uncategorized/job_completion.md) monitoring. Alerts are funneled to the `#alerts` Slack channel with a S4 severity:

<!-- ## Links to further Documentation -->
