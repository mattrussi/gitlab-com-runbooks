# Increased Error Rate

## First and foremost

*Don't Panic*

## Symptoms

- Message in prometheus-alerts _Increased Error Rate Across Fleet_
- PagerDuty Alert: _HighRailsErrorRate_

## Troubleshoot
### Kibana
  - [All 5xx statuses in rails](https://log.gitlab.net/app/kibana#/discover?_g=h@506727a&_a=h@3e371b9)
  - [All 5xx statuses by controller](https://log.gitlab.net/app/kibana#/visualize/edit/AWWoNujLXaPv1oP9gavK?_g=h@cfc15f8&_a=h@a80b883)
  - [Check for abuse from a specific IP](https://log.gitlab.net/app/kibana#/visualize/edit/AWWoQ9z4rqveOwJaKMd9?_g=h@cfc15f8&_a=h@9dcd243)
- Check the [triage overview](https://dashboards.gitlab.net/dashboard/db/triage-overview) dashboard for 5xx errors by backend.
- Check [Sentry](https://sentry.gitlab.net/gitlab/gitlabcom/) for new 500 errors.
- If the problem persists send a channel wide notification in `#development`.
