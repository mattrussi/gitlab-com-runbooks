local panels = import 'gitlab-monitoring/gitlab-dashboards/pgbouncer-panels.libsonnet';

panels.pgbouncer('pgbouncer-registry').overviewTrailer()
