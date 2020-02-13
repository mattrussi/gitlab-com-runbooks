
# Td-agent stackdriver dropped messages

## Reason

A large number of dropped messages were detected in the td-agent logfile.

## Troubleshooting

Dropping logs by the stackdriver plugin for fluentd occurs usually because of
api limits. This could be for the following reasons:

1. The rate of log messages have increased dramatically, this could either be
   that we are hitting the maximum number of write requests per project of 60000
   or the size of a single request which cannot exceed 10MB.
2. An individual log message is too long, there is a 256KB limit for a single log
   line.

### API limit for sending logs

#### Payload limit

This is the most common reason for dropping logs, it means that the stackdriver
plugin is buffering too much data before sending a payload to stackdriver

```
2020-02-05 17:18:40 +0000 [warn]: #0 Failed to extract log entry errors from the error details: {
  "error": {
    "code": 400,
    "message": "Request payload size exceeds the limit: 10485760 bytes.",
    "status": "INVALID_ARGUMENT"
  }
}
. error_class=JSON::ParserError error="NilClass"
2020-02-05 17:18:40 +0000 [warn]: #0 Dropping 20480 log message(s) error="Invalid request" error_code="400"
```

This can be avoided by reducing the `buffer_chunk_limit` in the plugin
configuration. This currently defaults to `3M`, it is not recommended to set
this lower than 1MB to avoid hitting the project limit for api requests.

#### Project limit

If `buffer_chunk_limit` is set too low, or there is a sharp increase in logs we
might hit the project limit for stackdriver write events, this is 60K/minute and
cannot be increased.

```

2018-11-21 14:41:02 +0000 [warn]: #0 failed to flush the buffer. retry_time=0 next_retry_seconds=2018-11-21 14:41:03 +0000 chunk="57b2d3a969abaa00611a44587d996854" error_class=Google::Apis::RateLimitError error="RESOURCE_EXHAUSTED: Quota exceeded for quota metric 'logging.googleapis.com/write_requests' and limit 'WriteRequestsPerMinutePerProject' of service 'logging.googleapis.com' for consumer 'project_number:805818759045'."
```

To avoid hitting the limit you can only either increase the
`buffer_chunk_limit` or look to reduce log volume by either excluding logs are
removing logs from fluentd.

### Log line limit

This type of error occurs when a single log line exceeds the maximum line
length. There are currently a couple known issues with very large log messages:

* https://gitlab.com/gitlab-org/gitlab/issues/205237
* https://gitlab.com/gitlab-org/gitlab/issues/202612#note_284173031

```
Dropping 1 log message(s) error="Log entry with size 279.7K exceeds maximum size
of 256.0K" error_code="google.rpc.Code[3]
```

These logs are infrequent and shouldn't cause an alert, if we start seeing more
of these large log messages ensure that there is an issue open for the endpoint
and adjust the alert threshold.
