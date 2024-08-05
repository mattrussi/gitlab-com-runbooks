# Duo Chat Playbook

## Table of Contents

- [Overview](#overview)
- [Quick Links](#services)
- [Duo Chat Error Codes](#duo-chat-error-codes)
- [Further troubleshooting](#further_troubleshooting)


## Overview

Sometimes it's hard to debugging where an issue quickly when you get an error code within GitLab Duo. Often times, when you encounter error code, there may be multiple teams may own the feature or it may not have been implemented by the Duo Chat team. The following should be give any GitLab team member a quick start guide for debugging any issue.

## Quick Links

- [Anthropic API Status Page](https://status.anthropic.com/)
- [AI Gateway Grafana Dashboard](https://dashboards.gitlab.net/d/ai-gateway-main/ai-gateway3a-overview?orgId=1)
- [GitLab Sidekiq logs](https://log.gprd.gitlab.net/app/discover#/view/de602330-fde3-11ee-afdf-41b4671bc1cc?_g=h@0938cf7&_a=h@96877b0)
    -  The following link points directly GitLab's `pubsub-sidekiq-inf-gprd*` elastic index

Log links:
- [AIGW logs](https://log.gprd.gitlab.net/app/discover#/?_g=h@5e3096a&_a=h@4785d23)
- [Sidekiq logs](https://log.gprd.gitlab.net/app/discover#/view/de602330-fde3-11ee-afdf-41b4671bc1cc?_g=h@0938cf7&_a=h@96877b0)
- [Monolith logs](https://log.gprd.gitlab.net/app/discover#/?_g=h@5e3096a&_a=h@cf0db95)
    - We enqueue a sidekiq job for the process of handling our GitLab Duo action. If the log doesn't in the other two indexes, there's a chance an error exists before calling the background jobs.


## Types of Duo Chat Errors

All of GitLab Duo Chat [error codes are documented in the following ](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/user/gitlab_duo_chat/troubleshooting.md#the-gitlab-duo-chat-button-is-not-displayed) page. To discover what the issue is please use the error code prefix letter to help choose where to search in Elastic logs.

### Error Code Layer Identifier

| Code | Layer           |
|------|-----------------|
| M    | Monolith - A network communication error in the monolith layer.     |
| G    | AI Gateway - A data formatting/processing error in the AI gateway layer.     |
| A    | Third-party API - An authentication or data access permissions error in a third-party API.|


### Debugging Error Codes A1000-6000

Normally, when you recieve an error code starting with 'A', there's an issue regarding either a timeout or limit access due to rate limiting, etc with our third party llm provider. The first step to take is make sure their are no on-going outages.

Check to see the Anthropic Status page is not reporting any issues:
- [Anthropic API Status Page](https://status.anthropic.com/)

Check to see if Google Cloud Platform is currently not reporting any issues:
- [Google Cloud Platform Issues](https://status.cloud.google.com/)

If nothing is reported, investigate any issues within the AIGW which acts as our proxy service for communicating with Third Party LLMs
- [Log Link](https://log.gprd.gitlab.net/app/r/s/pbW4x)


### Debugging Error Codes M3002 - M3004

The following error codes deal with error codes associate 

The issue most likely exists within the Monolith. Access the [Sidekiq logs](https://log.gprd.gitlab.net/app/discover#/view/de602330-fde3-11ee-afdf-41b4671bc1cc?_g=h@0938cf7&_a=h@96877b0)

1. Update the `json.error_code: "<error_code>" ` field with the M error code.
2. Update the `json.meta.user: "<user_name>" ` field with the specific users.
3. Add the last 7 days as the time frame for searching for relevant logs. 

The following should 

### Debugging Error Codes M3005

The following error is pretty straightforward for reasoning.
>access_forbidden

### Debugging Error Codes M4000 

The following all relate towards a slash command issues.

| Slash Command | Tool | Team Owner |
|---------------|------|------------|
| /troubleshoot              |      | #           |
| /explain            |      |            |
| /tests             |      |            |
| /summarize_comments             |      |            |
| /refactor            |      |            |
| /vulnerability_explain            |      |            |



## Further troubleshooting

Assuming you can't find anything of value within the error logs to help debug an issue, you may want to enabled `expanded_ai_logging` to see input and ouput of any of the following AI tools. 

To enable expanded AI logging, access #production channel and run the following command.

```
/chatops run features set expanded_ai_logging --user=<USERNAME>
```

**WARNING**: **DO NOT ENABLE FOR CUSTOMERS**. Please submit a Support Intake ticket if you want to enable to debug a customer specific issues. Try to replicate the issue with you development environment before submitting a customer support ticket.

With the following enabled, you can debug any production or development logs to see the internal input/outputs of the GitLab Duo Chat.
