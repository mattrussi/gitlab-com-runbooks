## How to set a maintenance window to exlucde from SLA

With [this MR](https://gitlab.com/gitlab-com/runbooks/-/merge_requests/5887/diffs) to the metrics catalog, we can make sure that the SLA does not include maintenance events in SLA calculations.

The Event should have a pre-approved Change Issue and followed the proper notification checklists.

To set the flag, ssh onto the read-write console node (console-01-sv-gprd.c.gitlab-production.internal) or another production VM with node_exporter running.
The node_exporter for prometheus has a directory configured for the textfile.directory flag where we can set a file up for metrics:
--collector.textfile.directory=/opt/prometheus/node_exporter/metrics.

To start the maintenance:
```
cd /opt/prometheus/node_exporter/metrics
touch gitlab_maintenance_mode.prom
cat << EOF
# HELP gitlab_maintenance_mode record maintenance window
# TYPE gitlab_maintenance_mode untyped
gitlab_maintenance_mode 1
EOF >> gitlab_maintenance_mode.prom
```

When the maintenance mode is over:
```
cat << EOF
# HELP gitlab_maintenance_mode record maintenance window
# TYPE gitlab_maintenance_mode untyped
gitlab_maintenance_mode 0
EOF >> /opt/prometheus/node_exporter/metrics/gitlab_maintenance_mode.prom
```

We can use at jobs to start/finish the maintenance window:

echo -e "# HELP gitlab_maintenance_mode record maintenance window\n# TYPE gitlab_maintenance_mode untyped\ngitlab_maintenance_mode 1\n" > gitlab_maintenance_mode.prom | at -t 202308301637

echo -e "# HELP gitlab_maintenance_mode record maintenance window\n# TYPE gitlab_maintenance_mode untyped\ngitlab_maintenance_mode 0\n" > gitlab_maintenance_mode.prom | at -t 202308301638
