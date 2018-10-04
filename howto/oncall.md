# So you got yourself on call

To start with the right foot let's define a set of tasks that are nice things to do before you go any further in your week

By performing these tasks we will keep the [broken window effect](https://en.wikipedia.org/wiki/Broken_windows_theory) under control, preventing future pain and mess.

## Things to keep an eye on

### On-call issues

First check [the on-call issues][on-call-issues] to familiarize yourself with what has been happening lately. Also, keep an eye on the [#production][slack-production] and [#incident-management][slack-incident-management] channels for discussion around any on-going issues.

### Alerts

Start by checking how many alerts are in flight right now

-   go to the [fleet overview dashboard](https://dashboards.gitlab.net/dashboard/db/fleet-overview) and check the number of Active Alerts, it should be 0. If it is not 0
    -   go to the alerts dashboard and check what is [being triggered](https://prometheus.gitlab.com/alerts) and watch the [#alerts][slack-alerts], [#alerts-general][slack-alerts-general], and [#alerts-gstg][slack-alerts-gstg] channels for alert notifications; each alert here should point you to the right runbook to fix it.
    -   if they don't, you have more work to do.
    -   be sure to create an issue, particularly to declare toil so we can work on it and suppress it.

### Nodes status

-   go to your chef repo and run `knife status`
-   if you see hosts that are red it means that chef hasn't been running there for a long time
-   check the on-call issues to see if they are intentionally disabled
    -   if not, and there is no mention of any ongoing issue in slack, mention it in [#production][slack-production] and begin investigating why `chef-client` has not been running there.

### Prometheus targets down

Check how many targets are not scraped at the moment. alerts are in flight right now, to do this:

-   go to the [fleet overview dashboard](https://dashboards.gitlab.net/dashboard/db/fleet-overview) and check the number of Targets down. It should be 0. If it is not 0
    -   go to the [targets down list](https://prometheus.gitlab.com/consoles/up.html) and check what is.
    -   try to figure out why there is scraping problems and try to fix it. Note that sometimes there can be temporary scraping problems because of exporter errors.
    -   be sure to create an issue, particularly to declare toil so we can work on it and suppress it.

[on-call-issues]: https://gitlab.com/gitlab-com/infrastructure/issues?scope=all&utf8=%E2%9C%93&state=all&label_name[]=oncall
[slack-alerts]: https://gitlab.slack.com/channels/alerts
[slack-alerts-general]: https://gitlab.slack.com/channels/alerts-general
[slack-alerts-gstg]: https://gitlab.slack.com/channels/alerts-gstg
[slack-incident-management]: https://gitlab.slack.com/channels/incident-management
[slack-production]: https://gitlab.slack.com/channels/production

