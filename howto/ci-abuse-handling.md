## How we operate today?

* https://performance.gitlab.net/dashboard/db/ci?refresh=5m&orgId=1 - look at the queues,
* CI Abuse Dashboard: https://log.gitlap.com/app/kibana#/dashboard/5d3921f0-79e0-11e7-a8e2-f91bfad41e34
* Set the time window to 24 hours and auto-refresh at around 5 minutes. This dashboard will show orange/red for any retry/trigger activity, It aggregates identical links and sorts them, Heatmap at top to detect retries it is worthy looking at, it goes to #security-alerts channel via elastalert
* Sidekiq Dashboard: https://log.gitlap.com/app/kibana#/dashboard/873fa6a0-10da-11e7-9012-e9f2fcd19778
* Pending jobs on shared runners by project ID: https://performance.gitlab.net/dashboard/db/ci?refresh=5m&panelId=33&fullscreen&orgId=1
* Running jobs on shared runners by project ID: https://performance.gitlab.net/dashboard/db/ci?refresh=5m&panelId=60&fullscreen&orgId=1
* Pipeline cancellation script: https://gitlab.com/gitlab-com/spam-master/blob/master/cancel_pipelines.rb _modify this script to cancel running, pending, or both as needed, Turn off shared runners, go ahead cancel running ones, go cancel rest ones_

## CI Abuse Block Procedures:

### Block user
* Disable project shared runners:
 * Go to Project > CI/CD > Settings
 * Disable Shared Runners
* Remove project scheduled pipelines:
 * Go to Project > CI/CD > Schedules
 * Remove all entries
* Cancel all running jobs, then pending.
* If repeated abuse from one email domain, blacklist the domain. If they use random subdomains use a wildcard: `*.trashemail.co” in addition to “trashemail.co`.

### Runner IDS Dashboard: https://log.gitlap.com/app/kibana#/dashboard/a51f1ca0-766a-11e7-8c1c-bf5bffdb4aa2
* Rules are stored at: https://dev.gitlab.org/cookbooks/packer-runner-machines/blob/master/assets/suricata/custom.rules
* ElastAlert rules should be created for any alerts with severity higher than 7 or so.
* False-positives and chatty rules should be disabled in: https://gitlab.com/briann/suricata-runner => gitlab-org/ci-cd
* ElastAlert configuration is stored on the log.gitlap.com server. Rules are in the /etc/elastalert/rules directory. 	
 * Each rule contains a Slack webhook URL that is sensitive.
 * The contents of the alerts in general are sensitive and cannot be made public.
 * For that reason there is not yet a repository for storing these rules.

### Needed accesses
* Admin access to GitLab.com (required to script with API),
