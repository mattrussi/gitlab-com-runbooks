local panels = import 'gitlab-monitoring/gitlab-dashboards/patroni-panels.libsonnet';

panels.patroni('patroni-registry')
