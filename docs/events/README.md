## Infrastructure events

Infrastructure events are log messages that helpful for [incident management](https://about.gitlab.com/handbook/engineering/infrastructure/incident-management/) to help answer the question **what changes happened leading up to the event?**

There are two ElasticSearch indexes that are used for events, `events-gstg` and `events-gprd`.
These indexes are both configured in the non-prod ElasticSearch cluster nonprod-log.gitlab.net so that we are not tied to the availability of the production for event records.

### CI Variables

There is a dedicated user in the nonprod cluster for sending events in the 1Password production vault named "User for sending infra events to ElasticSearch".

In CI, use the variable named `$ES_EVENT_PASS` and `$ES_NONPROD_HOST` for sending events with `curl`.

### How to send an event

Sending event is purposely kept as simple as possible, because we send events from multiple projects, mostly from CI pipelines.
The following fields are recommended:

| name      | type | required |
| ---       | ---  | --- |
| `time`    | string | yes |
| `type`    | string | yes |
| `message` | string | yes |
| `env`     | string | yes |
| `username`    | string | yes |
| `source`  | string | no |
| `diff_url`    | string | no |

* `message`: Free-form text describing the event
* `env`: One of `gprd`, `gprd-cny`, `gstg`
* `username`: GitLab username if available, if unknown use `unknown` as the value.
* `type`: The type of event, for example: `deployment`, `configuration`, `alert`, etc.
* `diff_url`: optional HTTP link, if a list of changes are available.
* `source`: optional source, may be a URL to a pipeline or job or free-form text

When using values from CI, use the CI variable name as the field name.
For example `CI_JOB_URL`, `CI_PIPELINE_URL`


```
curl -X PUT  https://event-user:$ES_EVENT_PASS@$ES_NONPROD_HOST:9243/events-gprd/_doc/1" -H 'Content-Type: application/json' -d' { "time": "$(date -u +%FT%T.%3NZ)", "type": "configuration", "message": "Test event", "env": "gprd", "username": "$GITLAB_USER_LOGIN", "source": "$CI_JOB_URL" }'
```
