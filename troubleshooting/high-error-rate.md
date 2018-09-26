# Increased Error Rate

## First and foremost

*Don't Panic*

## Symptoms

- Message in prometheus-alerts _Increased Error Rate Across Fleet_
- PagerDuty Alert: _HighRailsErrorRate_

## Troubleshoot
### Kibana
  - [All 5xx statuses in rails](https://log.gitlab.net/goto/1bb0fbde4bbf4d43fb8ce0b16c6bdcbf)
  - [All 5xx statuses by controller](https://log.gitlab.net/goto/c39fa97831441eefa41fb13fd20adee3)
  - [Check for abuse from a specific IP](https://log.gitlab.net/goto/d51a1f9ad9149f835b0c34565f5e8ff7)
- Check the [triage overview](https://dashboards.gitlab.net/dashboard/db/triage-overview) dashboard for 5xx errors by backend.
- Check [Sentry](https://sentry.gitlab.net/gitlab/gitlabcom/) for new 500 errors or an uptick.
- If the problem persists send a channel wide notification in `#development`.
