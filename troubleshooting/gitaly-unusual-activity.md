# Gitaly unusual activity alert

## First and foremost

*Don't Panic*

## Symptoms

* Alert on Slack: _Unusual Gitaly activity for a project has been detected. Review the runbook at https://gitlab.com/gitlab-com/runbooks/tree/master/troubleshooting/gitaly-unusual-activity.md for more details_

## 1. Review the suspicious activity

- Keep in mind that this is an open-ended alert, so it alerts to suspicious activity, rather than pin-pointing an issue.
- Use this as an informational alert, combine it with other signals
- Also review the abuse dashboard:  https://log.gitlab.net/app/kibana#/dashboard/AWSIfVZhTIzC7JP6Xxn1

## 2. Evaluate impact

- If the affected Gitaly server is under load due to the activity this project is generating, consider disabling the project, at least temporarily
