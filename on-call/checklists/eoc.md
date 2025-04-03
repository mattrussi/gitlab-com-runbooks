# Engineer On Call (EOC) for GitLab.com

To start with the right foot let's define a set of tasks that are nice things to do before you go any further in your week.

By performing these tasks we will keep the [broken window effect][broken_window_effect] under control, preventing future pain and mess.

## Before your week of on-call shifts

- Join the `#eoc-general` slack channel
- Familiarize yourself with [Pagerduty][pagerduty] and [Incident.io][incidentio]
- Make sure you can receive test pages from [Pagerduty][pagerduty]
- Be prepared to respond to alerts within 15 minutes during your on-call time

## Beginning your daily on-call shift

Here is a suggested checklist of things to do at the start of an on-call shift:

- *Change Slack Icon*: Click name. Click `Set status`.
  Click grey smile face.
  Type `:pagerduty:`.
  Set `Clear after` to end of on-call shift.
  Click `Save`
- *Join alert slack channels if not already a member*:
  - `#production`
  - `#incidents-dotcom`
  - `#alerts-prod-abuse`
  - `#g_security_vulnmgmt_notifications`
- *Turn on slack channel notifications for these slack channels for
  `All new messages`*:
  - `#incidents-dotcom`
- At the start of each on-call day, read the on-call handover issue that has been assigned to you by the previous EOC, and familiarize yourself with any ongoing incidents.

## Ending your faily on-call shift

- *Turn off slack channel notifications*: Open notification preferences in monitored Slack channels from the previous checklist and return alerts to the desired values.
- *Leave noisy alert channels*: `/leave` alert channels (It's good to stay in `#alerts` and `#alerts-general`)
- [Comment on any open S1 incidents][open_s1_incidents]
- At the end of each on-call day, post a quick update in slack so the next person is aware of anything ongoing, any false alerts, or anything that needs to be handed over.

## Completing your week on on-call shifts

- Take a deep breath! You did it!
- Review your incidents and see if any of them need corrective actions, to be marked as resolved, or reviews filled out.
- Take note of any alerts that were not productive and use [these resources](../../docs/monitoring/alert_tuning.md) to make notifications more helpful.
- Schedule some down time to recouperate and relax. Being on call is stressful, even on a good week.

## Things to keep an eye on

### On-call issues

First check [active production incident issues][active-production-incident-issues] to familiarize yourself with what has been happening lately.
Also, keep an eye on the [#production][slack-production] and [#incidents-dotcom][slack-incident-management] channels for discussion around any on-going issues.

### Useful Dashboard to keep open

- [Platform Triage](https://dashboards.gitlab.net/goto/EEjfId3Ig?orgId=1)

### Slack sre-oncall alias

In Slack, there is an alias (@sre-oncall) that will notify the current EoC.
Responding to these requests is best effort and you are empowered to decide the best response given the current production situation.
You can also always reach out to your team, the `#eoc-general` Slack channel, or others to help delegate work that 

### Incidents

For each new incident you are aware of, regardless of the source, you should declare an incident in [Incident.io][incidentio].
You can declare incidents in Slack using the `/inc` command.

### Alerts

Alertmanager, deadmansnitch, incidents, and any other alert generating process will go to the `GitLab Production` service in Pagerduty and page someone (you).
If you want to see current alerts, you can check [Pagerdury][pagerduty].
Alerts that page you or appear in Slack are not the only way to know there is a incident going on.
You may be made aware of other problems from individuals mentioning problems to you, or opening incidents, or seeing problems first-hand.
There is no wrong way to be made aware of an incident.

When you are paged, or are made aware of a problem, follow this general workflow of steps:

1. Acknowledge the alert if you are able to investigate and work the problem.
You have 15 minutes to acknowledge before the alert is escelated automatically to the Incident Manager On Call (IMOC).


1. If the alert is not part of an existing incident, open an incident using the `/inc` Slack command.


### Security

If you find any abnormal or suspicious activity during the course of your on call on-call rotation, please do not hesitate to [contact security](https://handbook.gitlab.com/handbook/security/security-operations/sirt/engaging-security-on-call/).

## Rotation Schedule

We use [PagerDuty](https://gitlab.pagerduty.com) to manage our on-call rotation schedule and alerting for emergency issues.
We currently have a split schedule between [EMEA][pagerduty-emea], [AMER][pagerduty-amer], and [APAC][pagerduty-apac] for on-call rotations in each geographical region.

The AMER, APAC, and EMEA schedules have a [shadow schedule][pagerduty-shadow] which we use for on-boarding new engineers to the on-call rotations.

When a new engineer joins the team and is ready to start shadowing for an on-call rotation, [overrides][pagerduty-overrides] should be enabled for the relevant on-call hours during that rotation.
Once they have completed shadowing and are comfortable/ready to be inserted into the primary rotations, update the membership list for the appropriate schedule to [add the new team member][pagerduty-add-user].

This [pagerduty forum post][pagerduty-shadow-schedule] was referenced when setting up the [blank shadow schedule][pagerduty-blank-schedule] and initial [overrides][pagerduty-overrides] for on-boarding new team members.

### Creating temporary PagerDuty maintenance windows

A temporary maintenance window may be created at any time using the `/chatops run pager pause` command in the [`#production` slack channel](https://gitlab.slack.com/archives/C101F3796).
The default window duration is `1 hour`. To schedule a window for another duration a [`ruby chronic`-compatible time specification](https://github.com/mojombo/chronic#examples) can be used like so: `--duration="2 hours"`.

For more options, use `/chatops run pager --help`:

```
Pause or resume pages.

Usage: pager <pause|resume> [options]

Options:

  -h, --help           Shows this help message
  --duration           Duration of window; default: 1 hour
  --environment        Environment [production,staging,test]; default: production
  --filter-by-creator  Filter maintenance windows by creator; default: false
```

Currently a maintenance window cannot be created for a duration smaller than 1 minute, according
to undocumented implementation in the PagerDuty API.


[active-production-incident-issues]:https://gitlab.com/gitlab-com/gl-infra/production/issues?state=open&label_name[]=Incident::Active
[open_s1_incidents]:                https://gitlab.com/gitlab-com/gl-infra/production/issues?scope=all&utf8=✓&state=opened&label_name%5B%5D=incident&label_name%5B%5D=S1

[incidentio]:                       https://app.incident.io

[pagerduty]:                        https://gitlab.pagerduty.com
[pagerduty-add-user]:               https://support.pagerduty.com/docs/editing-schedules#section-adding-users
[pagerduty-amer]:                   https://gitlab.pagerduty.com/schedules#POL1GSQ
[pagerduty-apac]:                   https://gitlab.pagerduty.com/schedules#PF02RF0
[pagerduty-emea]:                   https://gitlab.pagerduty.com/schedules#P40KYLY
[pagerduty-shadow]:                 https://gitlab.pagerduty.com/schedules#PZEBYO0
[pagerduty-blank-schedule]:         https://community.pagerduty.com/t/creating-a-blank-schedule/212
[pagerduty-shadow-schedule]:        https://community.pagerduty.com/t/creating-a-shadow-schedule-to-onboard-new-employees/214
[pagerduty-overrides]:              https://support.pagerduty.com/docs/editing-schedules#section-create-and-delete-overrides

[prometheus-azure]:                 https://prometheus.gitlab.com/alerts
[prometheus-azure-targets-down]:    https://prometheus.gitlab.com/consoles/up.html
[prometheus-gprd]:                  https://prometheus.gprd.gitlab.net/alerts
[prometheus-gprd-targets-down]:     https://prometheus.gprd.gitlab.net/consoles/up.html
[prometheus-app-gprd]:              https://prometheus-app.gprd.gitlab.net/alerts
[prometheus-app-gprd-targets-down]: https://prometheus-app.gprd.gitlab.net/consoles/up.html

[runbook-repo]:                     https://gitlab.com/gitlab-com/runbooks

[slack-alerts]:                     https://gitlab.slack.com/channels/alerts
[slack-alerts-general]:             https://gitlab.slack.com/channels/feed_alerts-general
[slack-incident-management]:        https://gitlab.slack.com/channels/incidents-dotcom
[slack-production]:                 https://gitlab.slack.com/channels/production

[broken_window_effect]:             https://en.wikipedia.org/wiki/Broken_windows_theory
