# HAProxy Logging

HAProxy logs are not indexed in *Elasticsearch* due to the volume of content.
You can view logs for a single HAProxy node by connecting and tailing local logs.
This may not be ideal when trying to investigate a site wide issue.

## Google BigQuery

HAProxy logs are collected into a table that can be queried in *BigQuery*.
This can provide the ability to search for patterns and look for recurring errors, etc.

### Finding HAProxy Logs in BigQuery

- Log into the Google Cloud web console and search or navigate to `BigQuery` in the appropriate project.
- In the `Explorer` on the left, you should open a `node` for your environment.
  This will most likely be called `gitlab-production` or `gitlab-staging`.
- You will see a `haproxy_logs` section you can expand and select the `haproxy_` table.

### Querying Logs in BigQuery

The `jsonPayload.message` field will most likely be a common item to look at since this contains the HAProxy log messages.
There are other fields to examine that may provide insights such as the `tt` field.
Here is an example query that could show `tt` values:

```sql
SELECT
  *
FROM
  `gitlab-production.haproxy_logs.haproxy_20231010`
WHERE
  jsonPayload.tt is not null
LIMIT 1000
```

BigQuery access is in alpha for gcloud command line access at this time.

## Logging Pipeline

This is how the logging pipeline works for the `haproxy` nodes.

The `haproxy` process sends its logs to `/dev/log` according to the following configurations.

```plaintext
global
  log /dev/log len 4096 local0
  log /dev/log len 4096 local1 notice

defaults
  log global
  option dontlognull
```

`/dev/log` is a Unix domain socket and everything that goes into it is received by the syslog daemon (`rsyslogd`).

Syslog is configured to read all configuration files in `/etc/rsyslog.d` directory, including the configurations for `haproxy` process.

```
$ cat /etc/rsyslog.conf

# Include all config files in /etc/rsyslog.d/
$IncludeConfig /etc/rsyslog.d/*.conf
```

```
$ cat /etc/rsyslog.d/49-haproxy.conf

# Create an additional socket in haproxy's chroot in order to allow logging via
# /dev/log to chroot'ed HAProxy processes
$AddUnixListenSocket /var/lib/haproxy/dev/log

# Send HAProxy messages to a dedicated logfile
:programname, startswith, "haproxy" {
  /var/log/haproxy.log
  stop
}
```

The [gprd-base-haproxy](https://gitlab.com/gitlab-com/gl-infra/chef-repo/-/blob/db605897e9a801529652bcab6af186a1b51983b0/roles/gprd-base-haproxy.json#L82)
Chef role includes the [gitlab_fluentd::haproxy](https://gitlab.com/gitlab-cookbooks/gitlab_fluentd/-/blob/master/recipes/haproxy.rb) recipe.
This recipe installs and configures Fluentd to collect and ship `haproxy` logs.

`td-agent` is a stable distribution package of Fluentd.

```
$ cat /etc/td-agent/td-agent.conf`

...
## include: modular configurations
@include conf.d/*.conf
...
```

```
$ cat /etc/td-agent/conf.d/haproxy.conf

## source: haproxy logs
<worker 0>
  <source>
    @type tail
    tag haproxy
    path /var/log/haproxy.log
    pos_file /var/log/td-agent/haproxy.log.pos
    <parse>
      @type multi_format
      ...
    </parse>
  </source>
</worker>

<filter haproxy>
  @type record_transformer
  enable_ruby
  <record>
    ...
  </record>
</filter>

## filter: hostname is not set on the haproxy logs
<filter haproxy>
  @type record_transformer
  enable_ruby
  <record>
    ...
  </record>
</filter>

<match haproxy>
  @type copy
  <store>
    @type google_cloud
    label_map {
      "tag": "tag"
    }
    buffer_chunk_limit 3m
    buffer_queue_limit 600
    flush_interval 60
    log_level info
  </store>


  @include ../prometheus-mixin.conf
</match>
```

The above output plugin (`google_cloud`) sends all the logs to Google Cloud *Stackdriver*.
You can query the logs from the Google Cloud *BigQuery*.
